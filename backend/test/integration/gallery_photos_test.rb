# frozen_string_literal: true

require "test_helper"

class GalleryPhotosTest < ActionDispatch::IntegrationTest
  setup do
    @school = School.find_by!(subdomain: "greenvalley")
    @admin_auth = login_as("principal@greenvalley.test")
    @image = fixture_file_upload("sample.png", "image/png")
  end

  test "admin uploads lists deletes and reorders gallery photos" do
    host! "greenvalley.localhost"

    post api_v1_admin_gallery_photos_path,
         params: { gallery_photo: { caption: "Sports day", image: @image } },
         headers: auth_headers(@admin_auth)

    assert_response :created
    photo_id = JSON.parse(response.body).dig("gallery_photo", "id")
    assert photo_id.present?

    get api_v1_admin_gallery_photos_path, headers: auth_headers(@admin_auth), as: :json
    assert_response :success
    captions = JSON.parse(response.body)["gallery_photos"].map { |row| row["caption"] }
    assert_includes captions, "Sports day"

    post api_v1_admin_gallery_photos_path,
         params: { gallery_photo: { caption: "Annual day", image: @image } },
         headers: auth_headers(@admin_auth)
    assert_response :created
    second_id = JSON.parse(response.body).dig("gallery_photo", "id")

    patch move_api_v1_admin_gallery_photo_path(second_id),
          params: { direction: "up" },
          headers: auth_headers(@admin_auth),
          as: :json
    assert_response :success
    assert_equal 1, JSON.parse(response.body).dig("gallery_photo", "position")

    get api_v1_public_gallery_photos_path, as: :json
    assert_response :success
    public_photos = JSON.parse(response.body)["gallery_photos"]
    assert_equal 2, public_photos.length
    assert public_photos.first["image_url"].present?

    delete api_v1_admin_gallery_photo_path(photo_id), headers: auth_headers(@admin_auth)
    assert_response :no_content
  end

  test "rejects more than six gallery photos" do
    host! "greenvalley.localhost"

    6.times do |index|
      post api_v1_admin_gallery_photos_path,
           params: { gallery_photo: { caption: "Photo #{index}", image: @image } },
           headers: auth_headers(@admin_auth)
      assert_response :created, "photo #{index} should be created"
    end

    post api_v1_admin_gallery_photos_path,
         params: { gallery_photo: { caption: "Too many", image: @image } },
         headers: auth_headers(@admin_auth)
    assert_response :unprocessable_entity
  end

  test "rejects oversized gallery photo" do
    host! "greenvalley.localhost"
    large = Tempfile.new(["large", ".png"])
    large.write("\x89PNG\r\n\x1a\n" + ("0" * (5.megabytes + 1)))
    large.rewind
    upload = Rack::Test::UploadedFile.new(large.path, "image/png")

    post api_v1_admin_gallery_photos_path,
         params: { gallery_photo: { caption: "Too big", image: upload } },
         headers: auth_headers(@admin_auth)

    assert_response :unprocessable_entity
    errors = JSON.parse(response.body)["errors"]
    assert_includes errors.join, "5 MB"
  ensure
    large.close
    large.unlink
  end


  private

  def login_as(email)
    host! "greenvalley.localhost"
    post api_v1_user_session_path,
         params: { user: { email: email, password: "password123" } },
         as: :json
    response.headers["Authorization"]
  end

  def auth_headers(token)
    { "Authorization" => token }
  end
end

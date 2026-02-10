class AuthorizeApiRequest
  def initialize(headers = {})
    @headers = headers
  end

  def call
    member
  end

  private

  attr_reader :headers

  def member
    @member ||= Member.find(decoded_auth_token[:member_id]) if decoded_auth_token
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def decoded_auth_token
    @decoded_auth_token ||= JsonWebToken.decode(http_auth_header)
  end

  def http_auth_header
    return headers['Authorization'].split(' ').last if headers['Authorization'].present?
    nil
  end

  def self.call(headers)
    new(headers).call
  end
end
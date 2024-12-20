# frozen_string_literal: true

# special processing for Minneapolis
class Minneapolis
  def self.parse_notices(page)
    notices = page['notices']

    now = DateTime.now

    notice = notices.detect do |n|
      (!n['publishDate'].to_s.empty? && DateTime.parse(n['publishDate']) < now) &&
        (!n['expireDate'].to_s.empty? && DateTime.parse(n['expireDate']) > now)
    end

    notice ? notice['html'] || '' : ''
  end
end

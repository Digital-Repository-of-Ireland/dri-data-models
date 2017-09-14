module DRI
  module Asset
    module Versions
      def record_version_committer(user)
        return if version.nil?
        VersionCommitter.create(version_id: version, committer_login: user.user_key)
      end
    end
  end
end
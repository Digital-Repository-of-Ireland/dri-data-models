module DRI
  module Asset
    module Versions
      def record_version_committer(user)
        object = digital_object
        VersionCommitter.create(
          version_id: object.object_version,
          obj_id: object.alternate_id,
          committer_login: user.to_s
        )
      end
    end
  end
end

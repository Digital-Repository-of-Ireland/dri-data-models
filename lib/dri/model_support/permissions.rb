# DRI namespace
module DRI
  #ModelSupport namespace
  module ModelSupport
    # Override Hydra permissions
    module Permissions
      extend ActiveSupport::Concern

      included do
        serialize :manager_groups, Array
        serialize :manager_users, Array
        serialize :edit_groups, Array
        serialize :edit_users, Array
        serialize :read_groups, Array
        serialize :read_users, Array
        serialize :discover_groups, Array
        serialize :discover_users, Array
      end

      # Grant discover permissions to the groups specified. Revokes discover permission for all other groups.
      # @param[String] groups a list of group names
      # @example
      #  r.discover_groups_string= 'one, two, three'
      #  r.discover_groups
      #  => ['one', 'two', 'three']
      #
      def discover_groups_string=(groups)
        self.discover_groups=groups.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def discover_groups_string
        self.discover_groups.join(', ')
      end

      # Grant discover permissions to the users specified. Revokes discover permission for all other users.
      # @param[Array] users a list of usernames
      # @example
      #  r.discover_users= ['one', 'two', 'three']
      #  r.discover_users
      #  => ['one', 'two', 'three']
      #
      #def discover_users=(users)
      #  set_discover_users(users, discover_users)
      #end

      # Grant discover permissions to the groups specified. Revokes discover permission for all other users.
      # @param[String] users a list of usernames
      # @example
      #  r.discover_users_string= 'one, two, three'
      #  r.discover_users
      #  => ['one', 'two', 'three']
      #
      def discover_users_string=(users)
        self.discover_users=users.split(/[\s,]+/)
      end

      # Display the users as a comma delimeted string
      def discover_users_string
        self.discover_users.join(', ')
      end

      # Grant read permissions to the groups specified. Revokes read permission for all other groups.
      # @param[String] groups a list of group names
      # @example
      #  r.read_groups_string= 'one, two, three'
      #  r.read_groups
      #  => ['one', 'two', 'three']
      #
      def read_groups_string=(groups)
        self.read_groups=groups.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def read_groups_string
        self.read_groups.join(', ')
      end

      # Grant read permissions to the groups specified. Revokes read permission for
      # any of the eligible_groups that are not in groups.
      # This may be used when different users are responsible for setting different
      # groups.  Supply the groups the current user is responsible for as the
      # 'eligible_groups'
      # @param[Array] groups a list of groups
      # @param[Array] eligible_groups the groups that are eligible to have their read permssion revoked.
      # @example
      #  r.read_groups = ['one', 'two', 'three']
      #  r.read_groups
      #  => ['one', 'two', 'three']
      #  r.set_read_groups(['one'], ['three'])
      #  r.read_groups
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_read_groups(groups, eligible_groups)
        set_entities(:read, :group, groups, eligible_groups)
      end

      # Grant read permissions to the groups specified. Revokes read permission for all other users.
      # @param[String] users a list of usernames
      # @example
      #  r.read_users_string= 'one, two, three'
      #  r.read_users
      #  => ['one', 'two', 'three']
      #
      def read_users_string=(users)
        self.read_users=users.split(/[\s,]+/)
      end

      # Display the users as a comma delimeted string
      def read_users_string
        self.read_users.join(', ')
      end

      # Grant edit permissions to the groups specified. Revokes edit permission for all other groups.
      # @param[String] groups a list of group names
      # @example
      #  r.edit_groups_string= 'one, two, three'
      #  r.edit_groups
      #  => ['one', 'two', 'three']
      #
      def edit_groups_string=(groups)
        self.edit_groups=groups.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def edit_groups_string
        self.edit_groups.join(', ')
      end

      # Grant edit permissions to the users specified. Revokes edit permission for
      # any of the eligible_users that are not in users.
      # This may be used when different users are responsible for setting different
      # users.  Supply the users the current user is responsible for as the
      # 'eligible_users'
      # @param[Array] users a list of users
      # @param[Array] eligible_users the users that are eligible to have their edit permssion revoked.
      # @example
      #  r.edit_users = ['one', 'two', 'three']
      #  r.edit_users
      #  => ['one', 'two', 'three']
      #  r.set_edit_users(['one'], ['three'])
      #  r.edit_users
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_edit_users(users, eligible_users)
        set_entities(:edit, :person, users, eligible_users)
      end

      def edit_users_string=(users)
        self.edit_users=users.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def edit_users_string
        self.edit_users.join(', ')
      end

      # Grant manager permissions to the groups specified. Revokes edit permission for all other groups.
      # @param[String] groups a list of group names
      # @example
      #  r.manager_groups_string= 'one, two, three'
      #  r.manager_groups
      #  => ['one', 'two', 'three']
      #
      def manager_groups_string=(groups)
        self.manager_groups=groups.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def manager_groups_string
        self.manager_groups.join(', ')
      end

      def manager_users_string=(users)
        self.manager_users=users.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def manager_users_string
        self.manager_users.join(', ')
      end
    end
  end
end

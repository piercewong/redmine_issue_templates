module Concerns
  module IssueTemplate
    module Common
      extend ActiveSupport::Concern

      #
      # Common scope both global and project scope template.
      #
      included do
        unloadable
        belongs_to :author, class_name: 'User', foreign_key: 'author_id'
        belongs_to :tracker
        before_save :check_default

        before_destroy :confirm_disabled

        validates :title, presence: true
        validates :tracker, presence: true
        acts_as_list scope: :tracker

        scope :enabled, -> { where(enabled: true) }
        scope :order_by_position, -> { order(:position) }
        scope :search_by_tracker, lambda { |tracker_id|
          where(tracker_id: tracker_id) if tracker_id.present?
        }

        scope :is_default, -> { where(is_default: true) }
        scope :not_default, -> { where(is_default: false) }

        after_destroy do |template|
          logger.info("[Destroy] #{self.class}: #{template.inspect}")
        end
      end

      #
      # Common methods both global and project scope template.
      #
      def enabled?
        enabled
      end

      def <=>(other)
        position <=> other.position
      end

      def checklist
        #
        # TODO: Exception handling
        #
        return [] if checklist_json.blank?
        JSON.parse(checklist_json)
      end

      def template_json
        template = {}
        template[self.class::Config::JSON_OBJECT_NAME] = generate_json
        template.to_json(root: true)
      end

      def generate_json
        result = attributes
        result[:checklist] = checklist
        result.except('checklist_json')
      end

      def template_struct(option = {})
        Struct.new(:value, :name, :class, :selected).new(id, title, option[:class])
      end

      def log_destroy_action(template)
        logger.info "[Destroy] #{self.class}: #{template.inspect}" if logger && logger.info
      end

      def confirm_disabled
        return unless enabled?
        errors.add :base, 'enabled_template_cannot_destroy'
        false
      end
    end
  end
end

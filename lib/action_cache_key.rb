class ActionController::Caching::Actions::ActionCachePath
    def path
        @cached_path ||= Digest::SHA1.hexdigest(@path)
    end
end

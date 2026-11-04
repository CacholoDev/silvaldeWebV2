module Carts
  # Destroys the carts without activity for longer than the retention window
  # (Cart::MAX_INACTIVITY), together with their lines. Quiet by design: with
  # nothing to purge it simply returns zero. Returns the number of destroyed
  # carts.
  class PurgeExpired
    def self.call
      Search.expired.destroy_all.size
    end
  end
end

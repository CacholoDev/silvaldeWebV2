class AddNumberToOrders < ActiveRecord::Migration[8.1]
  # Public number shown to the customer ("your order SV-K7M2QX"). Frozen
  # here so the migration stays self-contained even if the model changes:
  # 32 chars without 0/O/1/I, so the number can be dictated over the phone
  # without confusions. 32**6 ≈ 1.07 billion possible numbers.
  ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
  BODY_LENGTH = 6

  def up
    add_column :orders, :number, :string, limit: 16

    say_with_time "backfilling the public number of existing orders" do
      used = Set.new
      select_values("SELECT id FROM orders ORDER BY id").each do |id|
        number = generate_number(used)
        execute("UPDATE orders SET number = #{quote(number)} WHERE id = #{quote(id)}")
      end
    end

    change_column_null :orders, :number, false

    # Defence in depth: the model validates uniqueness too, but the database
    # is the real guarantee that two orders never share a public number.
    add_index :orders, :number, unique: true
  end

  def down
    remove_column :orders, :number
  end

  private

  def generate_number(used)
    loop do
      body = Array.new(BODY_LENGTH) { ALPHABET[SecureRandom.random_number(ALPHABET.length)] }.join
      number = "SV-#{body}"
      return number if used.add?(number)
    end
  end
end

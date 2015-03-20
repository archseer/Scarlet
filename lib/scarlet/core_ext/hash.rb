class Hash
  # Remaps a copy of the hash using the block. The block should return an array
  # containing the key and value. Array<key, value>
  # @return [Hash] the remapped hash.
  # @yield [key, value] Gives each key value pair of the hash to the block.
  def remap &block
    Hash[*self.map(&block).flatten]
  end

  # Remaps the hash using the block. The block should return an array
  # containing the key and value. Array<key, value>
  # @return (see #remap)
  # @yield (see #remap)
  def remap! &block
    self.replace remap(&block)
  end
end

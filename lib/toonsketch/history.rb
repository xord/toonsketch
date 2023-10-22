class History

  def initialize()
    @undos, @redos = [], []
  end

  def undo()
    return if @undos.empty?
    @undos.last.undo
    @redos.push @undos.pop
  end

  def redo()
    @return if @redos.empty?
    @redos.last.do
    @undos.push @redos.pop
  end

  def canUndo?()
    @undos.size > 0
  end

  def canRedo?()
    @redos.size > 0
  end

  def add(action)
    @undos << action
    @redos.clear
  end

  def clear()
    @undos.clear
    @redos.clear
  end

end# History

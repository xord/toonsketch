class History

  def initialize()
    @actions = []
  end

  def undo()
    @actions.pop.undo
  end

  def redo()
    raise NotImplementedError
  end

  def canUndo?()
    @actions.size > 0
  end

  def canRedo?()
    false
  end

  def add(action)
    @actions << action
  end

  def clear()
    @actions.clear
  end

  def size()
    @actions.size
  end

end# History

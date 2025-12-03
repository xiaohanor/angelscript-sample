class USketchbookPencilEraserTouchPaperCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	ASketchbookPencil Pencil;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Pencil.bIsActive)
			return false;

		if(!Pencil.IsEraserTouchingPaper())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Pencil.bIsActive)
			return true;

		if(!Pencil.IsEraserTouchingPaper())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		USketchbookPencilEventHandler::Trigger_OnEraserTouchPaper(Pencil);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		USketchbookPencilEventHandler::Trigger_OnEraserLiftOffPaper(Pencil);
	}
};
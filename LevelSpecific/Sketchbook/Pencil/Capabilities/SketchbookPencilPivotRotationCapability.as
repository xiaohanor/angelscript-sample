class USketchbookPencilPivotRotationCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

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
		if(!ShouldErase())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ShouldErase())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// We are active while erasing
		const float TargetPivotRotationAlpha = IsActive() ? 1 : 0;
		
		float PivotRotationAlpha = Pencil.GetPivotRotationAlpha();
		PivotRotationAlpha = Math::FInterpConstantTo(PivotRotationAlpha, TargetPivotRotationAlpha, DeltaTime, 1 / Sketchbook::RotateAroundPivotDuration);
		Pencil.SetPivotRotationAlpha(PivotRotationAlpha, this);
	}

	bool ShouldErase() const
	{
		check(HasControl());

		bool bErase = false;

		if(!Pencil.bIsActive)
		{
			bErase = false;
		}
		else if(Pencil.CurrentRequest.IsSet())
		{
			bErase = Pencil.CurrentRequest.Value.bErase;
		}
		else if(Pencil.HasValidRequestInQueue())
		{
			FSketchbookPencilRequest Request = Pencil.GetNextRequestInQueue();
			bErase = Request.bErase;
		}
		else
		{
			bErase = false;
		}

		return bErase;
	}
};
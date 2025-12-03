class UDanceShowdownPoseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);

	default TickGroup = EHazeTickGroup::Movement;

	UDanceShowdownPlayerComponent DanceComp;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DanceComp = UDanceShowdownPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DanceShowdown::GetManager().IsActive())
			return false;

		if(DanceComp.MonkeyOnFace != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DanceShowdown::GetManager().IsActive())
			return true;

		if(DanceComp.MonkeyOnFace != nullptr)
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
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector2D RawMoveInput2D = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			DanceComp.UpdateInput(RawMoveInput2D.Y, -RawMoveInput2D.X);
		}

		//Debug::DrawDebugString(Owner.ActorCenterLocation, "" + DanceComp.Pose);
		
		if(Player.Mesh.CanRequestLocomotion())
		{
			Player.Mesh.RequestLocomotion(n"DanceShowdown", this);
		}
	}
};
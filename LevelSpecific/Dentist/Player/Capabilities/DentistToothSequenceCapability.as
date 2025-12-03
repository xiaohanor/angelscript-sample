class UDentistToothSequenceCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 110;

	UDentistToothPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!(Player.bIsParticipatingInCutscene && Player.bIsControlledByCutscene))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!(Player.bIsParticipatingInCutscene && Player.bIsControlledByCutscene))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Override the mesh offsets performed on possession to place the player mesh origin at the capsule center
		Player.MeshOffsetComponent.SnapToRelativeLocation(this, Player.MeshOffsetComponent.AttachParent, FVector::ZeroVector, EInstigatePriority::Override);
		Player.Mesh.SetRelativeLocation(FVector(0, 0, 0));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Clear all our offsets and reset the mesh to where it should be for gameplay
		Player.MeshOffsetComponent.ClearOffset(this);
		Player.Mesh.SetRelativeLocation(FVector(0, 0, -Dentist::CollisionHeight));
	}
};
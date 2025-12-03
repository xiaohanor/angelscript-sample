class USandSharkHeightCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::LastMovement;
	ASandShark SandShark;
	USandSharkMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		MoveComp = USandSharkMovementComponent::Get(SandShark);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
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
		FVector MeshLocation;
		FVector RootLocation;
		if (HasControl())
		{
			MeshLocation = SandShark.ActorUpVector * MoveComp.AccDive.Value;
			RootLocation = FVector(SandShark.AccMeshForwardOffset.Value, 0, -200);
			SandShark.SyncedMeshLocationComp.SetValue(MeshLocation);
			SandShark.SyncedRootLocationComp.SetValue(RootLocation);
		}
		else
		{
			MeshLocation = SandShark.SyncedMeshLocationComp.GetValue();
			RootLocation = SandShark.SyncedRootLocationComp.GetValue();
		}
		SandShark.SharkRoot.SetRelativeLocation(RootLocation);
		SandShark.SharkMesh.SetRelativeLocation(MeshLocation);
	}
};
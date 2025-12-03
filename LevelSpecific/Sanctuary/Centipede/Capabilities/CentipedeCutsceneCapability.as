
class UCentipedeCutsceneCapability : UHazeCapability
{
	default CapabilityTags.Add(CentipedeTags::Centipede);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	ACentipede Centipede;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Centipede = Cast<ACentipede>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Centipede.bIsControlledByCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Centipede.bIsControlledByCutscene)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Block collisions and gameplay and shiet
		Centipede.BlockCapabilities(CentipedeTags::Centipede, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Get cutscene's last mesh transforms
		TArray<FTransform> CutsceneRelativeTransforms = Centipede.Mesh.GetComponentSpaceTransforms();

		// Copy them unto segments
		for (auto& Segment : Centipede.Segments)
		{
			int BoneIndex = Centipede.Mesh.GetBoneIndex(Segment.Name);
			if (BoneIndex >= 0)
			{
				FVector WorldLocation = (CutsceneRelativeTransforms[BoneIndex] * Centipede.Mesh.WorldTransform).Location - FVector::UpVector * Centipede::SegmentRadius;
				Segment.PreviousLocation = WorldLocation;
			    Segment.WorldLocation = WorldLocation;

				// Debug::DrawDebugSphere(WorldLocation, 100, 12, FLinearColor::Green, 5, 100 );
			}
		}

		Centipede.UnblockCapabilities(CentipedeTags::Centipede, this);

		Centipede.bWasControlledByCutsceneLastFrame = true;
	}
}
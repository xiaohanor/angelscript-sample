class UPlayerSubsurfaceEnablementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);
	default TickGroup = EHazeTickGroup::PostWork;

	int ViewIndex;

	UPlayerRenderingSettingsComponent SettingsComp;
	TPerPlayer<UPlayerRenderingSettingsComponent> RenderingSettingsComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SettingsComp = UPlayerRenderingSettingsComponent::GetOrCreate(Player);

		if (Player.IsMio())
			ViewIndex = 0;
		else
			ViewIndex = 1;
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
		for (AHazePlayerCharacter AffectPlayer : Game::Players)
			RenderingSettingsComponents[AffectPlayer] = UPlayerRenderingSettingsComponent::GetOrCreate(AffectPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AHazePlayerCharacter AffectPlayer : Game::Players)
			AffectPlayer.Mesh.SetAvoidSubsurfaceInView(ViewIndex, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ViewLocation = Player.ViewLocation;

		for (AHazePlayerCharacter AffectPlayer : Game::Players)
		{
			UPlayerRenderingSettingsComponent RenderingSettingsComp = RenderingSettingsComponents[AffectPlayer];

			float MaxSSSDistance = Math::GetMappedRangeValueClamped(
				FVector2D(20, 50),
				FVector2D(1000, 250),
				AffectPlayer.ViewFOV) * RenderingSettingsComp.SubsurfaceDistanceMultiplier.Get();

			FVector AffectPlayerLocation = AffectPlayer.ActorCenterLocation;
			float AffectPlayerDistance = AffectPlayerLocation.Distance(ViewLocation);

			if (AffectPlayerDistance > MaxSSSDistance)
			{
				AffectPlayer.Mesh.SetAvoidSubsurfaceInView(ViewIndex, true);

				for (UHazeSkeletalMeshComponentBase AdditionalMesh : RenderingSettingsComp.AdditionalSubsurfaceMeshes)
				{
					if (IsValid(AdditionalMesh))
						AdditionalMesh.SetAvoidSubsurfaceInView(ViewIndex, true);
				}
			}
			else
			{
				AffectPlayer.Mesh.SetAvoidSubsurfaceInView(ViewIndex, false);

				for (UHazeSkeletalMeshComponentBase AdditionalMesh : RenderingSettingsComp.AdditionalSubsurfaceMeshes)
				{
					if (IsValid(AdditionalMesh))
						AdditionalMesh.SetAvoidSubsurfaceInView(ViewIndex, false);
				}
			}
		}
	}
};

class UPlayerRenderingSettingsComponent : UActorComponent
{
	TArray<UHazeSkeletalMeshComponentBase> AdditionalSubsurfaceMeshes;
	TInstigated<float> SubsurfaceDistanceMultiplier(1.0);
}
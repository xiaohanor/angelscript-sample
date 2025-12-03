UCLASS(HideCategories = "Navigation Collision Rendering Debug Actor Cooking", Meta = (HighlightPlacement))
class ASkylineDaClubDancingAnimationVolume : AVolume
{
	UPROPERTY(EditAnywhere)
	UHazeLocomotionFeatureBase ZoeFeature;
	UPROPERTY(EditAnywhere)
	UHazeLocomotionFeatureBase MioFeature;
	UPROPERTY(EditAnywhere)
	UHazeLocomotionFeatureBase MioFeature_Sheathed;

	UPROPERTY(EditAnywhere)
	int Prio = 100;

	TPerPlayer<UHazeLocomotionFeatureBase> AppliedFeature;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			UHazeLocomotionFeatureBase FeatureToApply = nullptr;

			if (IsOverlappingActor(Player))
			{
				if (Player.IsMio())
				{
					auto BladeComp = UGravityBladeUserComponent::Get(Player);
					if (BladeComp.IsBladeSheathed())
						FeatureToApply = MioFeature_Sheathed;
					else
						FeatureToApply = MioFeature;
				}
				else
				{
					FeatureToApply = ZoeFeature;
				}
			}

			if (AppliedFeature[Player] != FeatureToApply)
			{
				if (AppliedFeature[Player] != nullptr)
					Player.RemoveLocomotionFeature(AppliedFeature[Player], this);
				if (FeatureToApply != nullptr)
					Player.AddLocomotionFeature(FeatureToApply, this, Prio);
				AppliedFeature[Player] = FeatureToApply;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Player : Game::Players)
		{
			if (AppliedFeature[Player] != nullptr)
				Player.RemoveLocomotionFeature(AppliedFeature[Player], this);
		}
	}
}
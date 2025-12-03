class USerpentLightningStormCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SerpentLightningStorm");

	FSplinePosition CurrentSplinePosition;
	ASerpentLightningStorm LightningStorm;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightningStorm = Cast<ASerpentLightningStorm>(Owner);
		CurrentSplinePosition = LightningStorm.SplineToFollow.Spline.GetSplinePositionAtSplineDistance(0);
		LightningStorm.SetActorLocationAndRotation(CurrentSplinePosition.WorldLocation, CurrentSplinePosition.WorldRotation);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 3)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Speed = LightningStorm.SerpentHead.MovementSpeed + LightningStorm.SerpentHead.RubberbandSpeed;
		CurrentSplinePosition.Move(Speed * DeltaTime);
		LightningStorm.SetActorLocationAndRotation(CurrentSplinePosition.WorldLocation, CurrentSplinePosition.WorldRotation);

		FPlane KillPlane(CurrentSplinePosition.WorldLocation, CurrentSplinePosition.WorldForwardVector);
		for (auto Player : Game::Players)
		{
			if (!Player.ActorCenterLocation.IsAbovePlane(KillPlane))
			{
				Player.KillPlayer();
			}
		}
	}
};

UCLASS(Abstract)
class ASerpentLightningStorm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineToFollow;

	UPROPERTY(EditInstanceOnly)
	ASerpentHead SerpentHead;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"SerpentLightningStormCapability");
};
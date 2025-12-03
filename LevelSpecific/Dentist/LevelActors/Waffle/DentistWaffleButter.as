UCLASS(Abstract)
class ADentistWaffleButter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CollisionMeshComp;
	default CollisionMeshComp.SetHiddenInGame(true);
	default CollisionMeshComp.SetCastShadow(false);

	UPROPERTY(DefaultComponent, Attach = CollisionMeshComp)
	UStaticMeshComponent VisualMeshComp;
	default VisualMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default VisualMeshComp.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent MovementResponseComp;

	UPROPERTY()
	FHazeTimeLike ButterBounceTimeLike;
	default ButterBounceTimeLike.UseSmoothCurveZeroToOne();

	TArray<ADentistFallingHeartWaffle> ChildWaffles;

	private FVector InitialRelativeScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementResponseComp.OnGroundPoundedOn.AddUFunction(this, n"HandleGroundPound");
		ButterBounceTimeLike.BindUpdate(this, n"ButterBounceTimeLikeUpdate");

		InitialRelativeScale = VisualMeshComp.GetRelativeScale3D();

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true);

		for (auto AttachedActor : AttachedActors)
		{
			auto AttachedWaffle = Cast<ADentistFallingHeartWaffle>(AttachedActor);

			if (AttachedWaffle != nullptr)
				ChildWaffles.AddUnique(AttachedWaffle);
		}
	}

	UFUNCTION()
	private void ButterBounceTimeLikeUpdate(float CurrentValue)
	{
		float ScaleX = InitialRelativeScale.X * CurrentValue;
		float ScaleY = InitialRelativeScale.Y * CurrentValue;
		float ScaleZ = InitialRelativeScale.Z / CurrentValue;
		VisualMeshComp.SetRelativeScale3D(FVector(ScaleX, ScaleY, ScaleZ));
	}

	UFUNCTION()
	private void HandleGroundPound(AHazePlayerCharacter GroundPoundPlayer, FHitResult Impact)
	{
		ButterBounceTimeLike.PlayFromStart();

		
		int FallingWaffleCount = 0;
		for (auto Waffle : ChildWaffles)
		{
			if(Waffle.State == EDentistFallingHeartWaffleState::Falling)
				continue;

			Waffle.Fall();
			FallingWaffleCount++;
		}

		BP_Audio_OnGroundPounded(FallingWaffleCount);
	}

	/**
	 * AUDIO
	 */

	/**
	 * When the butter is ground pounded, all waffles around the butter will immediately fall
	 */
	UFUNCTION(BlueprintEvent, Category = "Audio")
	void BP_Audio_OnGroundPounded(int FallingWaffleCount) {}
};
UCLASS(Abstract)
class ADentistBouncyGumDropCandy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CollisionMeshComp;
	default CollisionMeshComp.SetHiddenInGame(true);
	default CollisionMeshComp.SetCastShadow(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent VisualMeshComp;
	default VisualMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent MovementResponseComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComponent; 

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ScaleTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ImpactTimeLike;

	UPROPERTY(EditDefaultsOnly)
	bool bExplodes = false;

	UPROPERTY(EditDefaultsOnly, meta = (EditCondition="bExplodes", EditConditionHides))
	UNiagaraSystem ExplosionVFX;

	private FVector InitialRelativeScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRelativeScale = VisualMeshComp.GetRelativeScale3D();

		MovementResponseComp.OnBouncedOn.AddUFunction(this, n"OnBouncedOn");
		MovementImpactCallbackComponent.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpacted");
		ScaleTimeLike.BindUpdate(this, n"ScaleTimeLikeUpdated");
		ImpactTimeLike.BindUpdate(this, n"ImpactTimeLikeUpdate");

		if (bExplodes)
			ScaleTimeLike.BindFinished(this, n"ScaleTimeLikeFinished");
	}

	UFUNCTION()
	private void HandleGroundImpacted(AHazePlayerCharacter Player)
	{
		if (!ScaleTimeLike.IsPlaying())
		{
			ImpactTimeLike.PlayFromStart();
			BP_Audio_OnJiggle(Player);
		}
	}

	UFUNCTION()
	private void OnBouncedOn(AHazePlayerCharacter Player, EDentistToothBounceResponseType Type, FHitResult Impact)
	{
		// Bounces are handled by HandleGroundImpacted
		if(Type == EDentistToothBounceResponseType::Bounce)
			return;

		ScaleTimeLike.PlayFromStart();

		if(Type == EDentistToothBounceResponseType::GroundPound)
		{
			BP_Audio_OnGroundPounded(Player);
		}

		if(bExplodes)
			BP_Audio_OnStartBursting(Player);

		if (ImpactTimeLike.IsPlaying())
			ImpactTimeLike.Stop();
	}

	UFUNCTION()
	private void ScaleTimeLikeUpdated(float CurrentValue)
	{
		float ScaleX = InitialRelativeScale.X * CurrentValue;
		float ScaleY = InitialRelativeScale.Y * CurrentValue;
		float ScaleZ = InitialRelativeScale.Z / CurrentValue;
		VisualMeshComp.SetRelativeScale3D(FVector(ScaleX, ScaleY, ScaleZ));
	}

	UFUNCTION()
	private void ScaleTimeLikeFinished()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ActorCenterLocation);
		BP_Audio_OnBurst();
		DestroyActor();
	}

	UFUNCTION()
	private void ImpactTimeLikeUpdate(float CurrentValue)
	{
		float ScaleX = InitialRelativeScale.X * CurrentValue;
		float ScaleY = InitialRelativeScale.Y * CurrentValue;
		float ScaleZ = InitialRelativeScale.Z / CurrentValue;
		VisualMeshComp.SetRelativeScale3D(FVector(ScaleX, ScaleY, ScaleZ));
	}

	/**
	 * AUDIO
	 */
	UFUNCTION(BlueprintEvent, Category = "Audio")
	private void BP_Audio_OnJiggle(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent, Category = "Audio")
	private void BP_Audio_OnGroundPounded(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent, Category = "Audio")
	private void BP_Audio_OnStartBursting(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent, Category = "Audio")
	private void BP_Audio_OnBurst() {}
};
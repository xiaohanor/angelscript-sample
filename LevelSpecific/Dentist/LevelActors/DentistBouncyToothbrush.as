UCLASS(Abstract)
class ADentistBouncyToothbrush : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PanPivot;

	UPROPERTY(DefaultComponent, Attach = PanPivot)
	USceneComponent ToothBrushPivot;

	UPROPERTY(DefaultComponent, Attach = ToothBrushPivot)
	UHazeCapsuleCollisionComponent CollisionComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComponent;

	UPROPERTY(DefaultComponent, Attach = ToothBrushPivot)
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent, Attach = ToothBrushPivot)
	USceneComponent BrushHeadPivot;

	UPROPERTY(DefaultComponent, Attach = BrushHeadPivot)
	UStaticMeshComponent BrushHeadMeshComp;

	UPROPERTY(EditAnywhere)
	float ImpulseStrength = 1000.0;

	UPROPERTY(EditAnywhere)
	FDentistToothApplyRagdollSettings RagdollSettings;

	UPROPERTY(EditAnywhere)
	float PanDegrees = 30.0;

	UPROPERTY(EditAnywhere)
	float PanStartingAlpha = 0.0;
	float PanOffset;

	FHazeTimeLike BrushTimeLike;
	default BrushTimeLike.UseLinearCurveZeroToOne();
	default BrushTimeLike.bFlipFlop = true;
	default BrushTimeLike.bLoop = true;
	default BrushTimeLike.Duration = 0.1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BrushTimeLike.BindUpdate(this, n"BrushTimeLikeUpdate");
		BrushTimeLike.Play();

		MovementImpactCallbackComponent.OnWallImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpact");
		MovementImpactCallbackComponent.OnGroundImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpact");
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		FVector SplineLocation = SplineComp.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
		FVector ImpulseDirection = (Player.ActorLocation - SplineLocation).GetSafeNormal();
		FVector Impulse = ImpulseDirection * ImpulseStrength + FVector::UpVector * 500.0;

		if (Impulse.Z < 500.0)
			Impulse.Z = 1000.0;

		auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
		if(ResponseComp != nullptr)
		{
			ResponseComp.OnImpulseFromObstacle.Broadcast(this, Impulse, RagdollSettings);
		}
	}

	UFUNCTION()
	private void BrushTimeLikeUpdate(float CurrentValue)
	{
		BrushHeadMeshComp.SetRelativeLocation(FVector::ForwardVector * CurrentValue * 50.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Paning
		float PanAlpha = (Math::Sin(Time::GameTimeSeconds + PanOffset) * 0.5) + 0.5; 

		PanPivot.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, PanDegrees, PanAlpha), 0.0));
	}
};
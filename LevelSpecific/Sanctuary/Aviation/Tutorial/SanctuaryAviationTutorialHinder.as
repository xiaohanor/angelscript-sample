class ASanctuaryAviationTutorialHinder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateRoot;

	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UFauxPhysicsAxisRotateComponent RotateComp1;

	UPROPERTY(DefaultComponent, Attach = RotateComp1)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UCapsuleComponent DamageOverlap;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect ForceFeedbackEffect;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		{
			TArray<UShapeComponent> ShapeComps;
			GetComponentsByClass(UShapeComponent, ShapeComps);
			for (auto TriggerComp : ShapeComps)
			{
				TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleTriggerOverlap");
			}
		}
	}

	UFUNCTION()
	private void HandleTriggerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (IsValid(OtherActor))
		{
			auto Player = Cast<AHazePlayerCharacter>(OtherActor);
			if (Player != nullptr)
			{
				Player.DamagePlayerHealth(0.1);
				if (ForceFeedbackEffect != nullptr)
					Player.PlayForceFeedback(ForceFeedbackEffect, false, true, this);
				FauxPhysics::ApplyFauxImpulseToActorAt(this, Player.ActorLocation, Arrow.ForwardVector * 1700.0);
			}
		}
	}
};
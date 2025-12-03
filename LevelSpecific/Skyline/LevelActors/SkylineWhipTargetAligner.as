class ASkylineWhipTargetAligner : AHazeActor
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	USkylineWhipTargetAlignerDrawComponent PerchPointDrawComp;
#endif

	UPROPERTY(EditAnywhere)
	float Radius;

	TArray<AActor> AttachedActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAttachedActors(AttachedActors);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Direction = (Game::Zoe.ActorLocation - ActorLocation).GetSafeNormal2D();

		for(AActor AttachedActor: AttachedActors)
		{
			AttachedActor.ActorLocation = ActorLocation + Direction * Radius;
		}
	}
}

class USkylineWhipTargetAlignerDrawComponent : UHazeEditorRenderedComponent
{
	default bIsEditorOnly = true;
	default SetHiddenInGame(true);

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR

		ASkylineWhipTargetAligner Aligner = Cast<ASkylineWhipTargetAligner>(Owner);
		if(Aligner == nullptr)
			return;

		SetActorHitProxy();

		DrawCircle(Aligner.ActorLocation, Aligner.Radius);
#endif
	}
}
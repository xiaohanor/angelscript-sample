event void FPrinceLanded();

UCLASS(Abstract)
class ASketchBookPrinceFalling : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent FauxTranslateComp;

	UPROPERTY(DefaultComponent, Attach = FauxTranslateComp)
	UFauxPhysicsWeightComponent FauxWeightComp;

	UPROPERTY(DefaultComponent, Attach = FauxTranslateComp)
	USketchbookArrowResponseComponent ArrowResponseComp;

	UPROPERTY(DefaultComponent, Attach = FauxTranslateComp)
	UHazeSkeletalMeshComponentBase Mesh;

	default FauxWeightComp.bApplyGravity = false;
	default FauxWeightComp.bApplyInertia = false;

	bool bLanded = false;

	UPROPERTY(EditAnywhere)
	float FallHeight;

	UPROPERTY()
	FPrinceLanded PrinceLandedEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PrinceLandedEvent.AddUFunction(this,n"PrinceLanded");
		USketchbookArrowResponseComponent::Get(Cast<ASketchbookPrince>(AttachParentActor)).OnHitByArrow.AddUFunction(this, n"HitByArrow");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(GetActorLocation().Z <= FallHeight)
		{
			FauxWeightComp.bApplyGravity = false;
			SetActorLocation(FVector(GetActorLocation().X,GetActorLocation().Y,FallHeight));
			Landed();
			PrinceLandedEvent.Broadcast();
		}
	}

	UFUNCTION(BlueprintEvent)
	void PrinceLanded(){}

	UFUNCTION(BlueprintEvent)
	void Landed()
	{
		SetAnimTrigger(n"Landed");
		if(!bLanded)
		{
			UFallingPrinceEventHandler::Trigger_Landed(this);
			Print("LANDED");
			bLanded = true;
		}
	}

	UFUNCTION(BlueprintCallable)
	void TargetHit()
	{
		UFallingPrinceEventHandler::Trigger_ArrowHit(this);
		Print("ARROW HIT");
	}

	UFUNCTION()
	private void HitByArrow(FSketchbookArrowHitEventData ArrowHitData, FVector ArrowLocation)
	{
		if(ArrowLocation.Z <= Mesh.WorldLocation.Z)
		{
			if (ArrowHitData.GetImpactNormal().Y < 0)
				SetAnimTrigger(n"HitLeft");

			SetAnimTrigger(n"Hit");
		}
	}
};
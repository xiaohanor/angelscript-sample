event void FOnSummitPulleyPulling();
event void FOnSummitPulleyReleased();

class UPulleyInteractionComponent : USceneComponent
{

}

class APulleyInteraction : AHazeActor
{
	FOnSummitPulleyPulling OnSummitPulleyPulling;
	FOnSummitPulleyReleased OnSummitPulleyReleased;

	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UFauxPhysicsTranslateComponent TranslateComponent;
	default TranslateComponent.bConstrainX = true;
	default TranslateComponent.MinX = -2000;
	default TranslateComponent.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent)
	UPulleyInteractionComponent VisualiserComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComponent)
	UInteractionComponent InteractComp;
	default InteractComp.InteractionCapability = n"SummitPulleyInteractionCapability";
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	// Doing the teleport for the dragon manually, don't want to move the player
	default InteractComp.MovementSettings.Type = EMoveToType::NoMovement;

	UPROPERTY(EditAnywhere, Category = "Setup")
	AActor PulleyObject;

	UPROPERTY(EditAnywhere, Category = "Setup")
	AHazeCameraActor PulleyCamera;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<FVector> PulleyRopePoints;

	UPROPERTY(EditAnywhere, Category = "Settings")
	USummitPulleySettings PulleySettings;

	float MaxPulledBackLength;
	UHazeCrumbSyncedFloatComponent SyncedAlpha;

	bool bIsPulling;

	FVector StartLocation;

	// How much it's pulled, 0(not pulled) - 1(fully pulled)
	float PullAlpha = 0.0;
	float PulledDistance = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Only Zoe is able to interact with this, so makes sense to sync it on that players side
		SetActorControlSide(Game::Zoe);

		// Convert to world space, for when the pulley moves
		for(auto& Point : PulleyRopePoints) 
		{
			Point += ActorLocation;
		}

		if(PulleySettings != nullptr)
			ApplyDefaultSettings(PulleySettings);
		else
			PulleySettings = USummitPulleySettings::GetSettings(this);
		MaxPulledBackLength = TranslateComponent.MinX;
		StartLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		DrawDebugRope();
		UpdateAlpha();
	}

	float GetCurrentRopeTension()
	{
		FVector DeltaLoc = ActorLocation - PulleyObject.ActorLocation; 
		return -ActorForwardVector.DotProduct(DeltaLoc);
	}

	void UpdateAlpha()
	{
		PulledDistance = StartLocation.Distance(ActorLocation);
		PulledDistance = Math::Clamp(PulledDistance, 0, -TranslateComponent.MinX);

		if (PulledDistance != 0.0 && MaxPulledBackLength != 0.0)
			PullAlpha = PulledDistance / -MaxPulledBackLength;
	}

	void MovePulley(float Distance)
	{
		float PullResistance = 1 - PulleySettings.PulleyResistance.GetFloatValue(PullAlpha);
		float ModifiedDistance = Distance * PullResistance;

		TranslateComponent.ApplyMovement(ActorLocation, (ActorForwardVector * ModifiedDistance));
	}

	void DrawDebugRope()
	{
		if(PulleyRopePoints.Num() == 0)
			return;
		
		const float RopeThickness = 20;
		for(int i = 0; i < PulleyRopePoints.Num(); i++)
		{
			FVector PointLocation = PulleyRopePoints[i];
			Debug::DrawDebugSphere(PointLocation, 50, 12,  FLinearColor::White, 5);
		}

		Debug::DrawDebugLine(ActorLocation, PulleyRopePoints[0], FLinearColor::Blue, RopeThickness);

		for(int i = 0; i < PulleyRopePoints.Num() - 1; i++)
		{
			FVector PointLocation = PulleyRopePoints[i];
			FVector NextPoint = PulleyRopePoints[i+1];
			Debug::DrawDebugLine(PointLocation, NextPoint, FLinearColor::Blue, RopeThickness);
		}
		
		if(PulleyObject == nullptr)
			return;

		Debug::DrawDebugLine(PulleyRopePoints.Last(), PulleyObject.ActorLocation, FLinearColor::Blue, RopeThickness);
	}

	void EnterInteraction()
	{
		bIsPulling = true;

		TranslateComponent.SpringStrength = 0;
		OnSummitPulleyPulling.Broadcast();
	}

	void OnRelease()
	{
		OnSummitPulleyReleased.Broadcast();

		if(PulleySettings.bShouldStayAtFullyPulled &&
			PullAlpha >= PulleySettings.FullyPulledThreshold)
		{
			TranslateComponent.SpringStrength = 0;
		}
		else
		{
			TranslateComponent.SpringStrength = PulleySettings.SpringStrengthWhileNotPulling;
		}
		bIsPulling = false;
	}
}
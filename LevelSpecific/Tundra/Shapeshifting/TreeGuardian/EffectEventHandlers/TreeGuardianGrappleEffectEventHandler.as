
UCLASS(Abstract)
class UTreeGuardianGrappleEffectEventHandler : UTreeGuardianBaseEffectEventHandler
{
	UPROPERTY()
	UNiagaraSystem Asset_Impact;

	USceneComponent GrappleComp_Start;
	USceneComponent GrappleComp_End;

	float TravelDuration = 0.0;
	float TelegraphDuration = 0.0;
	float GrappleDuration = 0.0;
	float TimeStampGrappleInit = -1.0;
	float TimeStampGrappleActivated = -1.0;
	float GrappleTravelDuration = 15;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateNiagaraParams(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		DeactivateGrappleImmediately();
	}

    // Called when we transform into the tree guardian
	UFUNCTION(BlueprintOverride)
    void OnTransformedInto(FTundraPlayerTreeGuardianTransformParams Params) 
	{
		Super::OnTransformedInto(Params);

		DeactivateGrappleImmediately();
	}

 	// Called when we transform back into human form
	UFUNCTION(BlueprintOverride)
    void OnTransformedOutOf(FTundraPlayerTreeGuardianTransformParams Params) 
	{
		Super::OnTransformedOutOf(Params);

		DeactivateGrappleImmediately();
	}

	// Called when an ongoing grapple is interuppted by a death or shapeshift etc.
	UFUNCTION(BlueprintOverride)
	void OnRangedGrappleBlocked() 
	{
		DeactivateGrappleImmediately();
	}

	UFUNCTION(BlueprintOverride)
	void OnRangedGrappleInit(FTundraPlayerTreeGuardianRangedGrappleEnterEffectParams Params) 
	{
	}

	// Called when the roots should start growing from the tree guardian's hands towards the target
	UFUNCTION(BlueprintOverride)
	void OnStartGrowingOutRangedInteractionRoots(FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params) 
	{
		Super::OnStartGrowingOutRangedInteractionRoots(Params);

		if(Params.InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple)
		{
			GrappleComp_Start = Params.RootsOriginPoint;
			GrappleComp_End = Params.RootsTargetPoint;


			// this is the telegraph time when he is waving his arms before the roots actually comes out
			const float RelevantDelayBefoeStartGrowing = TreeGuardianComp.bCameFromGrapple ? Treeguardian::Grapple::AnimationDelays::GrowingRootsWhenAttached : Treeguardian::Grapple::AnimationDelays::GrowingRoots;
			const float RelevantDelayBeforeStartMoving = TreeGuardianComp.bCameFromGrapple ? Treeguardian::Grapple::AnimationDelays::MovingAfterGrowingRootsWhenAttached : Treeguardian::Grapple::AnimationDelays::MovingAfterGrowingRoots;

			TelegraphDuration = Params.GrowTime;
			GrappleDuration = Params.GrowTime;
			TravelDuration = Params.TravelTime + RelevantDelayBeforeStartMoving;

			ActivateGrapple();
			UpdateNiagaraParams(0.0);
			SpawnActivationImpact();
			//TimeStampGrappleActivated = Time::GetGameTimeSeconds();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRangedGrappleStartedEnter(FTundraPlayerTreeGuardianRangedGrappleEnterEffectParams Params) 
	{
		// DeactivateGrapple();
		GrappleTravelDuration = Params.GrappleDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnStartGrowingInRangedInteractionRoots(FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params) 
	{
		if(Params.InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple)
		{
			// this one isn't hooked up in the grapple capability at all.
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRangedGrappleReachedPoint() 
	{
		DeactivateGrapple();
		// DeactivateGrappleImmediately();
		SpawnDeactivationImpact();
	}

	void UpdateNiagaraParams(const float Dt) 
	{
		UNiagaraComponent GrappleVFX = GetRootsVFX();
		if(GrappleVFX.IsActive() == false)
			return;

		const FVector RootLocation_Start = GrappleComp_Start.GetWorldLocation();
		const FVector RootLocation_End = GrappleComp_End.GetWorldLocation();

		GrappleVFX.SetNiagaraVariableFloat("RootDuration", 10);

		///////////////////////////
		// Legacy asset support
		GrappleVFX.SetNiagaraVariableVec3("RootStart", RootLocation_Start);
		GrappleVFX.SetNiagaraVariableVec3("RootEnd", RootLocation_End);
		///////////////////////////

		GrappleVFX.SetNiagaraVariableVec3("BezierStart", RootLocation_Start);
		GrappleVFX.SetNiagaraVariableVec3("BezierEnd", RootLocation_End);

		GrappleVFX.SetNiagaraVariableVec3("HandPosition", RootLocation_Start);
		GrappleVFX.SetNiagaraVariableVec3("ObjectPosition", RootLocation_End);

		GrappleVFX.SetNiagaraVariableFloat("TelegraphDuration", TelegraphDuration);
		GrappleVFX.SetNiagaraVariableFloat("GrappleDuration", GrappleDuration);
		GrappleVFX.SetNiagaraVariableFloat("TravelDuration", TravelDuration);
		const float FullDuration = (TravelDuration + GrappleDuration);
		GrappleVFX.SetNiagaraVariableFloat("FullDuration", FullDuration);

		// GrappleVFX.SetNiagaraVariableVec3("GrappleTargetNormal", GrappleComp_End.ForwardVector);
		GrappleVFX.SetNiagaraVariableVec3("GrappleTargetNormal", (RootLocation_End-RootLocation_Start).GetSafeNormal());

		// PrintToScreen("GrappleDuration: " + GrappleDuration, 0.5, FLinearColor::Yellow);

		// Debug::DrawDebugSphere(RootLocation_End, 100, 12, FLinearColor::Yellow);
		// Debug::DrawDebugSphere(RootLocation_Start, 100, 12, FLinearColor::Red);
	}

	void SpawnActivationImpact()
	{
		const FVector SpawnLocation = GrappleComp_Start.GetWorldLocation();
		const FVector TargetLocation = GrappleComp_End.GetWorldLocation();
		const FRotator SpawnOrientation = FRotator::MakeFromZ(TargetLocation - SpawnLocation);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(
			Asset_Impact,
			SpawnLocation,
			SpawnOrientation
		);
	}

	void SpawnDeactivationImpact()
	{
		const FVector SpawnLocation = GrappleComp_End.GetWorldLocation();
		const FRotator SpawnOrientation = GrappleComp_End.GetWorldRotation();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(
			Asset_Impact,
			SpawnLocation,
			SpawnOrientation
		);
	}

	UNiagaraComponent GetRootsVFX() const
	{
		auto FoundComp = TreeGuardianActor.GetComponent( UNiagaraComponent, n"VFX_Roots_Grapple");
		UNiagaraComponent VFX = Cast<UNiagaraComponent>(FoundComp);
		return VFX;
	}

	void ActivateGrapple()
	{
		// GetRootsVFX().Activate(true);
		GetRootsVFX().Activate();
	}

	void DeactivateGrapple()
	{
		GetRootsVFX().Deactivate();
	}

	void DeactivateGrappleImmediately()
	{
		GetRootsVFX().DeactivateImmediate();
	}
}
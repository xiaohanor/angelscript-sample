
// Overrides audio materials based on which screen the player is visable.
class UPlayerFootSlideSplitTraversal : UHazePlayerCapability
{
	UPlayerAudioMaterialComponent PlayerMaterialComp;
	ASplitTraversalManager SplitManager;
	UPlayerSlideComponent SlideComp;
	UPlayerMovementAudioComponent MovementAudioComp;

	UPhysicalMaterialAudioAsset CurrentOverrideMaterial = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitManager = ASplitTraversalManager::GetSplitTraversalManager();
		PlayerMaterialComp = UPlayerAudioMaterialComponent::Get(Player);
		SlideComp = UPlayerSlideComponent::Get(Player);
		MovementAudioComp = UPlayerMovementAudioComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return SplitManager != nullptr && SlideComp.IsSlideActive();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return SplitManager == nullptr || !SlideComp.IsSlideActive();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovementAudioComp.OnFootSlideTrace.AddUFunction(this, n"OnFootSlideTrace");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MovementAudioComp.OnFootSlideTrace.UnbindObject(this);

		// Reset any override
		if (CurrentOverrideMaterial != nullptr)
		{
			CurrentOverrideMaterial = nullptr;

			if (PlayerMaterialComp != nullptr)
				SetMaterialOverride();
		}
	}

	UFUNCTION()
	private void OnFootSlideTrace(FVector InStartTrace, FVector InEndTrace)
	{
		// Should we override the material hit?
		UPhysicalMaterialAudioAsset NewMaterial = nullptr;
		FVector2D LeftScreenLocation;
		SceneView::ProjectWorldToScreenPosition(Game::Mio, InStartTrace, LeftScreenLocation);
		if (LeftScreenLocation.X > 0.5)
		{
			QueryMaterial(
				SplitManager.Position_ScifiToFantasy(InStartTrace), 
				SplitManager.Position_ScifiToFantasy(InEndTrace),
				NewMaterial);
		}

		if (CurrentOverrideMaterial != NewMaterial)
		{
			CurrentOverrideMaterial = NewMaterial;
			SetMaterialOverride();
		}
	}

	void SetMaterialOverride()
	{
		PlayerMaterialComp.SetMovementMaterialOverride(EFootType::None, CurrentOverrideMaterial, this);
		PlayerMaterialComp.SetMovementMaterialOverride(EFootType::Release, CurrentOverrideMaterial, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDebugVisible()
	{
		PrintToScreen("CurrentOverrideMaterial: "+ CurrentOverrideMaterial);
	}

	// More or less a copy from footslide capability.
	private bool QueryMaterial(const FVector& InStartTrace, const FVector& InEndTrace, UPhysicalMaterialAudioAsset& OutAudioPhysMat)
	{
		FHazeTraceSettings Trace = FHazeTraceSettings();
		Trace.TraceWithChannel(ECollisionChannel::AudioTrace);
		Trace.UseLine();

		// Shouldn't really happen
		if((InStartTrace - InEndTrace).IsNearlyZero())
			return false;

		FHitResult Result = Trace.QueryTraceSingle(InStartTrace, InEndTrace);
		
		if(!Result.bBlockingHit)
			return false;

		UPhysicalMaterial ContactPhysMat = AudioTrace::GetPhysMaterialFromHit(Result, Trace);

		if(ContactPhysMat == nullptr)
			return false;

		OutAudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(ContactPhysMat.AudioAsset);		
		return true;
	}
}
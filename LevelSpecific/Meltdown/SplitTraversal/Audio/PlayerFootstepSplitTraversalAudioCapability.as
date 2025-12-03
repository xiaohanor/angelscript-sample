
// Overrides audio materials based on which screen the player is visable.
class UPlayerFootstepSplitTraversalAudioCapability : UHazePlayerCapability
{
	UPlayerAudioMaterialComponent PlayerMaterialComp;
	ASplitTraversalManager SplitManager;
	UPlayerMovementAudioComponent MovementAudioComp;
	UPlayerFootstepTraceComponent TraceComp;


	UPhysicalMaterialAudioAsset LeftFootOverrideMaterial = nullptr;
	UPhysicalMaterialAudioAsset RightFootOverrideMaterial = nullptr;
	bool bIsInOppositeWorld = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitManager = ASplitTraversalManager::GetSplitTraversalManager();
		PlayerMaterialComp = UPlayerAudioMaterialComponent::Get(Player);
		MovementAudioComp = UPlayerMovementAudioComponent::Get(Player);
		TraceComp = UPlayerFootstepTraceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return SplitManager != nullptr && SplitManager.bSplitSlideActive;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return SplitManager == nullptr || !SplitManager.bSplitSlideActive;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovementAudioComp.OnFootTrace.AddUFunction(this, n"OnFootStepTrace");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MovementAudioComp.OnFootTrace.UnbindObject(this);

		ResetOverride(EFootType::Right, RightFootOverrideMaterial);
		ResetOverride(EFootType::Left,  LeftFootOverrideMaterial);
	}

	void ResetOverride(const EFootType InType, UPhysicalMaterialAudioAsset&inout Variable)
	{
		if (Variable != nullptr)
		{
			Variable = nullptr;
			PlayerMaterialComp.SetMovementMaterialOverride(InType, Variable, this);
		}
	}

	UFUNCTION()
	private void OnFootStepTrace(FPlayerFootstepTraceData InFootstepData)
	{
		// Should we override the material hit?
		UPhysicalMaterialAudioAsset NewMaterial = nullptr;

		FVector2D LeftScreenLocation;
		SceneView::ProjectWorldToScreenPosition(Game::Mio, InFootstepData.Start, LeftScreenLocation);
		if (LeftScreenLocation.X > 0.5)
		{
			// After art pass the geo isn't at the same level as scifi.
			// So we extend the traces
			auto ExtraDistanceVector = InFootstepData.End - InFootstepData.Start;

			FPlayerFootstepTraceData CopiedData = InFootstepData;
			CopiedData.Start = SplitManager.Position_ScifiToFantasy(InFootstepData.Start);
			CopiedData.End = SplitManager.Position_ScifiToFantasy(InFootstepData.End + ExtraDistanceVector);// + (InFootstepData.End - InFootstepData.Start));
			// Make sure the copied data is reset.
			CopiedData.Trace.bPerformed = false;

			if(TraceComp.PerformFootTrace_Sphere(CopiedData, CopiedData.Settings.SphereTraceRadius * 2, false, IsDebugActive()) && CopiedData.Trace.bGrounded)
			{
				NewMaterial = Cast<UPhysicalMaterialAudioAsset>(CopiedData.GroundedPhysMat.AudioAsset);
			}
			else
			{
				// Don't update material until we are off screen.
				return;
			}
		}

		auto& CurrentMaterial = InFootstepData.Foot == EFootType::Left ? LeftFootOverrideMaterial : RightFootOverrideMaterial;
		// PrintToScreen(f"Material - {CurrentMaterial}", Duration = 3);
		if (CurrentMaterial != NewMaterial)
		{
			CurrentMaterial = NewMaterial;
			SetMaterialOverride(InFootstepData.Foot, CurrentMaterial);
		}
	}

	void SetMaterialOverride(const EFootType InType, UPhysicalMaterialAudioAsset MaterialOverride)
	{
		PlayerMaterialComp.SetMovementMaterialOverride(InType, MaterialOverride, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDebugVisible()
	{
		PrintToScreen("LeftFootOverrideMaterial: " + LeftFootOverrideMaterial);
		PrintToScreen("RightFootOverrideMaterial: " + RightFootOverrideMaterial);
	}
}

UCLASS(Abstract)
class UWorld_Interactable_OilRig_HijackPanel_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void FailAutomatic(FOilRigShipHijackPanelEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void Fail(FOilRigShipHijackPanelEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void Success(FOilRigShipHijackPanelEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStopInteract(FOilRigShipHijackPanelEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStartInteract(FOilRigShipHijackPanelEventParams Params){}

	/* END OF AUTO-GENERATED CODE */

	AOilRigShipHijackManager Manager = nullptr;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Manager = Cast<AOilRigShipHijackManager>(HazeOwner);
		Manager.OnCompleted.AddUFunction(this, n"OnPuzzleCompeleted");
	}

	UFUNCTION(BlueprintEvent)
	void OnPuzzleCompeleted() {}

	UFUNCTION(BlueprintPure)
	AOilRigShipHijackPanel GetLeftPanel() const
	{
		return Manager.LeftPanel;
	}

	UFUNCTION(BlueprintPure)
	AOilRigShipHijackPanel GetRightPanel() const
	{
		return Manager.RightPanel;
	}

	UFUNCTION(BlueprintPure)
	float GetLeftPendulumAlpha() const
	{
		return Math::Lerp(-1, 1, Manager.LeftPanel.GetPendulumProgressAlpha());
	}

	UFUNCTION(BlueprintPure)
	float GetRightPendulumAlpha() const
	{
		return Math::Lerp(-1, 1, Manager.RightPanel.GetPendulumProgressAlpha());
	}
}
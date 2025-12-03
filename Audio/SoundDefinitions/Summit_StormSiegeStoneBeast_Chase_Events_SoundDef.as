
UCLASS(Abstract)
class USummit_StormSiegeStoneBeast_Chase_Events_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASerpentHead StoneBeast;

	UFUNCTION(BlueprintEvent)
	void OnEnter_Intro() {};
	UFUNCTION(BlueprintEvent)
	void OnEnter_Follow() {};
	UFUNCTION(BlueprintEvent)
	void OnEnter_LightningStrike() {};
	UFUNCTION(BlueprintEvent)
	void OnEnter_Waterfall() {};
	UFUNCTION(BlueprintEvent)
	void OnEnter_DebrisCrash() {};
	UFUNCTION(BlueprintEvent)
	void OnEnter_Islands() {};
	UFUNCTION(BlueprintEvent)
	void OnEnter_SpikeField() {};
	UFUNCTION(BlueprintEvent)
	void OnEnter_WindTunnel() {};
	UFUNCTION(BlueprintEvent)
	void OnEnter_CavernBreak() {};
	UFUNCTION(BlueprintEvent)
	void OnEnter_MountainClimb() {};	

	float CombinedSplinesDistance = 0;
	int CurrentSplineIndex = 0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		StoneBeast = Cast<ASerpentHead>(HazeOwner);

		for(auto& Spline : StoneBeast.SplineActors)
			CombinedSplinesDistance += Spline.Spline.SplineLength;
	}

	UFUNCTION(BlueprintEvent)
	void OnTransitionToNewSpline(FSerpentHeadSplineParams Params)
	{
		switch(Params.SplineIndex)
		{
			case(0): CurrentSplineIndex = 0; OnEnter_Intro(); if(IsDebugging()) {PrintToScreenScaled(f"Enter Intro", 2.f, FLinearColor::Green);} break;
			case(1): CurrentSplineIndex = 1; OnEnter_Follow(); if(IsDebugging()) {PrintToScreenScaled(f"Enter Follow", 2.f, FLinearColor::Green);} break;
			case(2): CurrentSplineIndex = 2; OnEnter_LightningStrike(); if(IsDebugging()) {PrintToScreenScaled(f"Enter LightningStrike", 2.f, FLinearColor::Green);} break;
			case(3): CurrentSplineIndex = 3; OnEnter_Waterfall(); if(IsDebugging()) {PrintToScreenScaled(f"Enter Waterfall", 2.f, FLinearColor::Green);} break;
			case(4): CurrentSplineIndex = 4; OnEnter_DebrisCrash(); if(IsDebugging()) {PrintToScreenScaled(f"Enter DebrisCrash", 2.f, FLinearColor::Green);} break;
			case(5): CurrentSplineIndex = 5; OnEnter_Islands(); if(IsDebugging()) {PrintToScreenScaled(f"Enter Islands", 2.f, FLinearColor::Green);} break;
			case(6): CurrentSplineIndex = 6; OnEnter_SpikeField(); if(IsDebugging()) {PrintToScreenScaled(f"Enter SpikeField", 2.f, FLinearColor::Green);} break;
			case(7): CurrentSplineIndex = 7; OnEnter_WindTunnel(); if(IsDebugging()) {PrintToScreenScaled(f"Enter WindTunnel", 2.f, FLinearColor::Green);} break;
			case(8): CurrentSplineIndex = 8; OnEnter_CavernBreak(); if(IsDebugging()) {PrintToScreenScaled(f"Enter CavernBreak", 2.f, FLinearColor::Green);} break;
			case(9): CurrentSplineIndex = 9; OnEnter_MountainClimb(); if(IsDebugging()) {PrintToScreenScaled(f"Enter MountainClimb", 2.f, FLinearColor::Green);} break;
			default: break;
		}
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Current Spline Alpha"))
	float GetCurrentSplineAlpha()
	{
		if(!StoneBeast.bIsActive || StoneBeast.CurrentSpline == nullptr)
			return 0.0;

		return StoneBeast.CurrentSpline.Spline.GetClosestSplineDistanceToWorldLocation(StoneBeast.ActorLocation) / StoneBeast.CurrentSpline.Spline.SplineLength;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Chase Spline Distance"))
	float GetTotalChaseSplineDistance()
	{
		if(!StoneBeast.bIsActive)
			return 0.0;
		
		float TotalDistance = 0;

		for(int i = CurrentSplineIndex; i < StoneBeast.SplineActors.Num(); ++i)
		{
			if(i < CurrentSplineIndex)
				TotalDistance += StoneBeast.SplineActors[i].Spline.SplineLength;
			else
			{
				TotalDistance += StoneBeast.SplineActors[i].Spline.GetClosestSplineDistanceToWorldLocation(StoneBeast.ActorLocation);
			}
		}

		return TotalDistance;
	}
	
}
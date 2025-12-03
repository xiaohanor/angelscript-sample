enum EIslandJetpackShieldotronFlyState
{
	IsGrounded,
	IsTakingOff,
	IsAirBorne,
	IsLanding
}

class UIslandJetpackShieldotronComponent : UActorComponent
{
	bool bHasFollowSpline = false;
	FHazeRuntimeSpline FollowSpline;
	
	FSplinePosition FollowSplinePosition;

	private	EIslandJetpackShieldotronFlyState CurrentState = EIslandJetpackShieldotronFlyState::IsGrounded;

	EIslandJetpackShieldotronFlyState GetCurrentFlyState() property
	{
		return CurrentState;
	}

	void SetCurrentFlyState(EIslandJetpackShieldotronFlyState NewState)
	{
		if (CurrentState == NewState)
			return;

		CurrentState = NewState;		
	}

	bool IsInAir()
	{
		return (CurrentState == EIslandJetpackShieldotronFlyState::IsAirBorne || CurrentState == EIslandJetpackShieldotronFlyState::IsTakingOff);
	}

#if EDITOR	
	UFUNCTION(DevFunction)
	void SetIsTakingOffState()
	{
		SetCurrentFlyState(EIslandJetpackShieldotronFlyState::IsTakingOff);
	}

	UFUNCTION(DevFunction)
	void SetIsLandingState()
	{
		SetCurrentFlyState(EIslandJetpackShieldotronFlyState::IsLanding);
	}
#endif


};
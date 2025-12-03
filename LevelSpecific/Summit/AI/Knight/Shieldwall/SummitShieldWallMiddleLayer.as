class ASummitShieldWallMiddleLayer : ASummitKnightShieldwallBase
{
	default MoveAnim.Duration = 1.0;
	default MoveAnim.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnim.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent KnightCanFindUsComp;

	//DEPRECATED, Remove when we can fix BP
	UFUNCTION()
	private void OnUpdate(float Alpha)
	{
	}

	UFUNCTION()
	void PlayFunction()
	{
	}

	UFUNCTION()
	void ReverseFunction()
	{
	}
	//DEPRECATED, Remove when we can fix BP
};

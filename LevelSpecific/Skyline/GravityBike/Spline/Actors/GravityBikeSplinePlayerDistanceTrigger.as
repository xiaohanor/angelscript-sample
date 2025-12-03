event void FGravityBikeSplineDistanceTriggerEnter(AGravityBikeSpline GravityBike, bool bWasFromReset);
event void FGravityBikeSplineDistanceTriggerExit(AGravityBikeSpline GravityBike);

enum EGravityBikeSplineDistanceTriggerState
{
	Before,
	Between,
	After
}

UCLASS(NotBlueprintable)
class AGravityBikeSplinePlayerDistanceTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UGravityBikeSplineDistanceTriggerComponent TriggerComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = TriggerComp)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(10);
	default BillboardComp.SpriteName = "T_Loft_Spline";
#endif

	UPROPERTY(EditAnywhere, Category = "Reset")
	private bool bResetOnRespawn = false;

	UPROPERTY(EditAnywhere, Category = "Reset")
	private bool bResetOnTeleport = false;

	// If we reset to within the Start and End distances, do we want to dispatch OnEnter again?
	UPROPERTY(EditAnywhere, Category = "Reset", Meta = (EditCondition = "bResetOnRespawn || bResetOnTeleport"))
	private bool bDispatchEnterIfResetToBetween = false;

	UPROPERTY()
	FGravityBikeSplineDistanceTriggerEnter OnEnter;

	UPROPERTY()
	FGravityBikeSplineDistanceTriggerExit OnExit;

	private bool bHasDispatchedEnter = false;
	private bool bHasDispatchedExit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(GravityBikeSpline::GetDriverPlayer());
		
		ResetOnTeleport();

		if(bResetOnRespawn)
		{
			auto RespawnComp = UPlayerRespawnComponent::Get(GravityBikeSpline::GetDriverPlayer());
			RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");
		}

		if(bResetOnTeleport)
		{
			auto TeleportComp = UTeleportResponseComponent::GetOrCreate(GravityBikeSpline::GetDriverPlayer());
			TeleportComp.OnTeleported.AddUFunction(this, n"OnPlayerTeleported");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!TriggerComp.HasValidSpline())
			return;

		auto State = GetCurrentState();
		if(!bHasDispatchedEnter)
		{
			if(State == EGravityBikeSplineDistanceTriggerState::Between || State == EGravityBikeSplineDistanceTriggerState::After)
			{
				auto DriverComp = UGravityBikeSplineDriverComponent::Get(GravityBikeSpline::GetDriverPlayer());
				OnEnter.Broadcast(DriverComp.GravityBike, false);
				bHasDispatchedEnter = true;
			}
		}
		else if(!bHasDispatchedExit)
		{
			if(State == EGravityBikeSplineDistanceTriggerState::After)
			{
				auto DriverComp = UGravityBikeSplineDriverComponent::Get(GravityBikeSpline::GetDriverPlayer());
				OnExit.Broadcast(DriverComp.GravityBike);
				bHasDispatchedExit = true;
			}
		}
	}

	EGravityBikeSplineDistanceTriggerState GetCurrentState() const
	{
		const AHazePlayerCharacter Player = GravityBikeSpline::GetDriverPlayer();
		const float PlayerDistanceAlongSpline = TriggerComp.GetSplineComp().GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);

		if(PlayerDistanceAlongSpline < TriggerComp.GetStartDistance())
			return EGravityBikeSplineDistanceTriggerState::Before;
		else if(PlayerDistanceAlongSpline > TriggerComp.GetEndDistance())
			return EGravityBikeSplineDistanceTriggerState::After;
		else
			return EGravityBikeSplineDistanceTriggerState::Between;
	}

	UFUNCTION()
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		if(!bResetOnRespawn)
			return;

		ResetOnTeleport();
	}

	UFUNCTION()
	private void OnPlayerTeleported()
	{
		if(!bResetOnTeleport)
			return;

		ResetOnTeleport();
	}

	void ResetOnTeleport()
	{
		switch(GetCurrentState())
		{
			case EGravityBikeSplineDistanceTriggerState::Before:
			{
				bHasDispatchedEnter = false;
				bHasDispatchedExit = false;

				break;
			}

			case EGravityBikeSplineDistanceTriggerState::Between:
			{
				if(bDispatchEnterIfResetToBetween)
				{
					auto DriverComp = UGravityBikeSplineDriverComponent::Get(GravityBikeSpline::GetDriverPlayer());
					OnEnter.Broadcast(DriverComp.GravityBike, true);
				}

				bHasDispatchedEnter = true;
				bHasDispatchedExit = false;

				break;
			}

			case EGravityBikeSplineDistanceTriggerState::After:
			{
				bHasDispatchedEnter = true;
				bHasDispatchedExit = true;

				break;
			}
		}
	}
};
UCLASS(Abstract)
class USkylineAllySocketHatchEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchBeginOpen(FSkylineAllyChargableCarHatchProgress Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchBeginClose() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchFinishedClose() {}
}

class ASkylineAllySocketHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HatchPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(EditInstanceOnly)
	ASkylinePowerPlugSocket Socket;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike HatchTimeLike;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditInstanceOnly)
	ASkylinePowerPlugSpool AssignedSpool;

	UPROPERTY()
	float OpenDuration = 2.0;

	bool bHatchOpen = false;
	bool bTargetedDontCloseHatch = false;

	bool bSocketActivated = false;
	float ProgressAlpha = 0.0;
	float DevToggleOpenCloseCooldown = 0.0;

	bool bAutoAimIsOn = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DevTogglesSkyline::AllyAutoSocketHatch.MakeVisible();

		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");
		HatchTimeLike.BindUpdate(this, n"HatchTimeLikeUpdate");
		HatchTimeLike.BindFinished(this, n"HatchTimeLikeFinished");
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleSocketActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleSocketDeactivated");

		Socket.SetActorEnableCollision(false);
		Socket.AutoAimTarget.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DevTogglesSkyline::AllyAutoSocketHatch.IsEnabled())
			DevToggling(DeltaSeconds);
		
		if (AssignedSpool != nullptr)
		{
			bool bInRange = AssignedSpool.ActorLocation.Distance(ActorLocation) <= AssignedSpool.CableLength * 1.1;
			bool bShouldHaveAutoAim = bHatchOpen && bInRange;
			//Debug::DrawDebugString(ActorLocation, "" + bShouldHaveAutoAim);
			if (bShouldHaveAutoAim != bAutoAimIsOn)
			{
				if (bShouldHaveAutoAim)
					Socket.AutoAimTarget.Enable(this);
				else
					Socket.AutoAimTarget.Disable(this);
				bAutoAimIsOn = bShouldHaveAutoAim;
			}
		}
	}

	private void DevToggling(float DeltaSeconds)
	{
		DevToggleOpenCloseCooldown -= DeltaSeconds;
		FLinearColor DebugColor = DevToggleOpenCloseCooldown > OpenDuration ? ColorDebug::Green : ColorDebug::Red;
		float OpenTimer = DevToggleOpenCloseCooldown;
		if (DevToggleOpenCloseCooldown > OpenDuration)
			OpenTimer -= OpenDuration;
		Debug::DrawDebugString(ActorLocation, "\n\n\n\n\n Timer " + OpenTimer, DebugColor);
		if (!bSocketActivated && DevToggleOpenCloseCooldown < 0.0)
		{
			DevToggleOpenCloseCooldown = OpenDuration * 2.0;
			if (!bHatchOpen)
				OpenHatch();
		}
	}

	UFUNCTION()
	private void HatchTimeLikeUpdate(float CurrentValue)
	{
		HatchPivot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Lerp(0.0, -180.0, CurrentValue)));

		ProgressAlpha = CurrentValue;
	}

	UFUNCTION()
	private void HatchTimeLikeFinished()
	{
		if (HatchTimeLike.IsReversed())
			USkylineAllySocketHatchEventHandler::Trigger_OnHatchFinishedClose(this);
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (bHatchOpen)
			return;

		OpenHatch();
	}

	UFUNCTION()
	private void HandleSocketActivated(AActor Caller)
	{
		bSocketActivated = true;
	}

	UFUNCTION()
	private void HandleSocketDeactivated(AActor Caller)
	{
		bSocketActivated = false;
		CloseHatch();
	}

	UFUNCTION()
	private void OpenHatch()
	{
		BP_Activated();

		HatchTimeLike.Play();

		bHatchOpen = true;
		GravityBladeTargetComponent.SetUsableByPlayers(EHazeSelectPlayer::None);
		Socket.SetActorEnableCollision(true);
		if (AssignedSpool == nullptr)
			Socket.AutoAimTarget.Enable(this);

		Timer::SetTimer(this, n"CloseHatch", OpenDuration);

		FSkylineAllyChargableCarHatchProgress Params;
		Params.ProgressAlpha = ProgressAlpha;

		USkylineAllySocketHatchEventHandler::Trigger_OnHatchBeginOpen(this, Params);
	}

	UFUNCTION()
	private void CloseHatch()
	{
		if (bSocketActivated)
			return;
		if (bTargetedDontCloseHatch)
			return;

		BP_Deactivated();
		if (AssignedSpool == nullptr)
			Socket.AutoAimTarget.Disable(this);

		HatchTimeLike.Reverse();

		GravityBladeTargetComponent.SetUsableByPlayers(EHazeSelectPlayer::Mio);
		bHatchOpen = false;
		Socket.SetActorEnableCollision(false);
		USkylineAllySocketHatchEventHandler::Trigger_OnHatchBeginClose(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activated()
	{

	}

	UFUNCTION(BlueprintEvent)
	private void BP_Deactivated()
	{
		
	}
};
// Mio
// Handles vertical input and setting height
// NOTE: This capability is on the WINCH, not on the player
class URemoteHackableWinchCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Input;

	ARemoteHackableWinch WinchActor;
	FHazeAcceleratedFloat AccInput;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WinchActor = Cast<ARemoteHackableWinch>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WinchActor.bHangingPlayerDead)
		{
			AccInput.SnapTo(0);
			return;
		}

		if(Game::Mio.HasControl())
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			float InputMultiplier = 1.0;
			if (Input.X < 0.0)
				InputMultiplier = Math::GetMappedRangeValueClamped(FVector2D(Prison::RemoteHackableWinch::MinHeight, Prison::RemoteHackableWinch::MinHeight + 500.0), FVector2D(0.0, 1.0), WinchActor.SyncedCurrentHeight.Value);
			WinchActor.SyncedHeightInput.SetValue(Input.X * InputMultiplier);
			AccInput.AccelerateTo(-Input.X * InputMultiplier, 1.0, DeltaTime);

			float NewCurrentHeight = WinchActor.SyncedCurrentHeight.Value - (AccInput.Value * Prison::RemoteHackableWinch::VerticalMaxSpeed * DeltaTime);
			NewCurrentHeight = Math::Clamp(NewCurrentHeight, Prison::RemoteHackableWinch::MinHeight, WinchActor.MaxHeight);

			float VerticalVelocity = (NewCurrentHeight - WinchActor.SyncedCurrentHeight.Value) / DeltaTime;
			WinchActor.SyncedHeightVelocity.Value = VerticalVelocity;

			WinchActor.SyncedCurrentHeight.SetValue(NewCurrentHeight);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		// Log the synced position error so we can compare between different sync methods
		auto OtherSide = Cast<ARemoteHackableWinch>(Debug::GetPIENetworkOtherSideForDebugging(WinchActor));
		if (OtherSide == nullptr || Time::GameTimeSeconds < 1.0)
			return;

		if(WinchActor.HasHorizontalControl())
		{
			TEMPORAL_LOG(WinchActor, "Predicted Position")
				.Point("ControlLocation", OtherSide.ActorLocation, 100, FLinearColor::Green)
				.Point("RemoteLocation", WinchActor.ActorLocation, 100)
				.Value("PositionError", (WinchActor.ActorLocation - OtherSide.ActorLocation).Size())
				.Value("ControlHeight", OtherSide.HookRoot.RelativeLocation.Z)
				.Value("RemoteHeight", WinchActor.HookRoot.RelativeLocation.Z)
				.Value("HeightError", Math::Abs(WinchActor.HookRoot.RelativeLocation.Z - OtherSide.HookRoot.RelativeLocation.Z))
			;
		}
		else if(WinchActor.HasVerticalControl())
		{
			TEMPORAL_LOG(WinchActor, "Vertical")
				.Value("Control;SyncedCurrentHeight", WinchActor.SyncedCurrentHeight.Value)
				.Value("Control;SyncedHeightVelocity", WinchActor.SyncedHeightVelocity.Value)
				.Value("Control;SyncedHeightInput", WinchActor.SyncedHeightInput.Value)

				.Value("Remote;SyncedCurrentHeight", OtherSide.SyncedCurrentHeight.Value)
				.Value("Remote;SyncedHeightVelocity", OtherSide.SyncedHeightVelocity.Value)
				.Value("Remote;SyncedHeightInput", OtherSide.SyncedHeightInput.Value)
			;

			TEMPORAL_LOG(WinchActor, "Predicted Position")
				.Point("ControlLocation", OtherSide.ActorLocation, 100, FLinearColor::Green)
				.Point("RemoteLocation", WinchActor.ActorLocation, 100)
				.Value("PositionError", (WinchActor.ActorLocation - OtherSide.ActorLocation).Size())
				.Value("ControlHeight", OtherSide.HookRoot.RelativeLocation.Z)
				.Value("RemoteHeight", WinchActor.HookRoot.RelativeLocation.Z)
				.Value("HeightError", Math::Abs(WinchActor.HookRoot.RelativeLocation.Z - OtherSide.HookRoot.RelativeLocation.Z))
			;
		}
	}
#endif
}
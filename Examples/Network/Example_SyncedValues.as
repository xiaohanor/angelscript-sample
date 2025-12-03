

class AExample_SyncedValues : AHazeActor
{
	// Specifies a component 
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedFloat;

	// By default, synced values sync at the "Standard" rate
	// This can be increased or decreased as needed.
	// The lower the sync rate, the larger the delay on the remote side
	// before changes to the value are reflected.
	// The higher the sync rate, the more traffic it uses.
	// Be very careful of using too much traffic!
	default SyncedFloat.SyncRate = EHazeCrumbSyncRate::Standard;

	// Vectors are also available to sync on the crumb trail
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedVector;

	// Rotators are also available to sync on the crumb trail
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotator;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HasControl())
		{
			// To use a synced value, set the Value property on the control side.
			float Height = ActorLocation.Z + DeltaTime;
			ActorLocation = FVector(ActorLocation.X, ActorLocation.Y, Height);

			SyncedFloat.Value = Height;
		}
		else
		{
			// On the remote side, it will then automatically be smoothly updated based on the global crumb trail
			float Height = SyncedFloat.Value;

			ActorLocation = FVector(ActorLocation.X, ActorLocation.Y, Height);
		}

		// Sync rate can be changed dynamically based on whether the player is interacting with something
		if (Game::Mio.GetDistanceTo(this) < 1000.0)
			SyncedFloat.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		else
			SyncedFloat.OverrideSyncRate(EHazeCrumbSyncRate::Standard);

		// Control side can be overridden on a synced component.
		//  When not overridden, the control side of the actor will be used.
		SyncedFloat.OverrideControlSide(Game::Mio);
	}

	void Teleport_Snap()
	{
		// If the control side does a teleport, you can force the synced value
		// to snap on the remote side, preventing it from lerping to the
		// teleported value.
		SyncedFloat.Value = 100.0;
		SyncedFloat.SnapRemote();
	}

	void PreventSyncing()
	{
		// Syncing can be temporarily blocked and unblocked,
		// this will cause no new values to be sent.
		SyncedFloat.BlockSync(Instigator = this);
		SyncedFloat.UnblockSync(Instigator = this);
	}

	void Transitions()
	{
		// In rare cases, it might be necessary to do a transition on the synced value.
		// This should always be used as a last resort when no other syncing options are feasible.
		// * Transitions MUST always happen with the same instigator on both sides.
		// * Sync values from before the remote side's transition are ignored.
		// * Sync values from after the control side's transition are not used until the remote side transitions too.

		SyncedFloat.TransitionSync(Instigator = this);
		SyncedFloat.TransitionSync(Instigator = n"NameOfTransition");
	}
};


/**
 * For advanced usage, it is possible to create a component class that
 * uses crumb trail syncing for an arbitrary struct:
 */
struct FExample_SyncedCameraValue
{
	FVector Location;
	FRotator Rotation;
	float FieldOfView = 70.0;
	bool bLetterboxed = false;
};

class UExample_CrumbSyncedCameraValues : UHazeCrumbSyncedStructComponent
{
	// By implementing an InterpolateValues function, we tell the
	// UHazeCrumbSyncedStructComponent which struct to use
	void InterpolateValues(FExample_SyncedCameraValue& OutValue, FExample_SyncedCameraValue A, FExample_SyncedCameraValue B, float64 Alpha)
	{
		// We are responsible for implementing the method by which these structs are lerped
		OutValue.Location = Math::Lerp(A.Location, B.Location, Alpha);
		OutValue.Rotation = Math::LerpShortestPath(A.Rotation, B.Rotation, Alpha);
		OutValue.FieldOfView = Math::Lerp(A.FieldOfView, B.FieldOfView, Alpha);
		OutValue.bLetterboxed = Alpha < 0.5 ? A.bLetterboxed : B.bLetterboxed;
	}

	private FExample_SyncedCameraValue CachedValue;
	const FExample_SyncedCameraValue& GetValue() property
	{
		GetCrumbValueStruct(CachedValue);
		return CachedValue;
	}

	void SetValue(FExample_SyncedCameraValue NewValue) property
	{
		SetCrumbValueStruct(NewValue);
	}

	// Retrieving the value from the synced component requires passing in a destination struct for the data
	void Example_Usage()
	{
		UExample_CrumbSyncedCameraValues SyncedStructComp = this;

		// To retrieve the current value: 
		FExample_SyncedCameraValue CurrentValue = GetValue();

		// To set a new value:
		FExample_SyncedCameraValue NewValue;
		SyncedStructComp.SetValue(CurrentValue);

		// Be careful when setting values every frame, it will continue sending
		// data even if you set the same value as it already was!
	}
};
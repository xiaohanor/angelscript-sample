/**
 * An action queue holds a sequence of delegates or capabilities that are activated one after the other.
 * This is often used to create boss attacks.
 * 
 * This example contains all the classes you might use for a simple example boss using an action queue.
 */

class AExampleActionQueueBoss : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	int CurrentPhase = 0;
	bool bAttacksPaused = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (HasControl() && ActionQueue.IsEmpty())
		{
			// Idle is a special action that makes the queue wait for a set duration
			ActionQueue.Idle(2.0);

			// Action capabilities can be queued directly on the action queue, they do not need to be added to a sheet
			ActionQueue.Capability(UExampleActionQueueJumpAttackCapability);

			// Action capabilities may also take a parameter struct (see the capability implementation below)
			FExampleActionQueueTargetedAttackParameters TargetParameters;
			TargetParameters.TargetPlayer = Game::Mio;
			ActionQueue.Capability(
				UExampleActionQueueTargetedAttackCapability,
				TargetParameters
			);

			// Delegates can be queued, and will be executed when the queue reaches this point
			ActionQueue.Event(this, n"TriggerNextPhase");

			// A 'Duration' action is a special kind of delegate that will be called every frame
			// for a predetermined duration. It will be passed an Alpha value between 0 and 1 as the duration reaches the end.
			ActionQueue.Duration(2.0, this, n"UpdateProgressToNextPhase");

			// IdleUntil can be used to idle the queue until a delegate returns true
			ActionQueue.IdleUntil(this, n"QueueShouldProceedToNextPhase");
		}
	}

	UFUNCTION()
	private void TriggerNextPhase()
	{
		Print("Trigger next phase!");
	}

	UFUNCTION()
	private void UpdateProgressToNextPhase(float Alpha)
	{
		Print(f"Progress to next phase: {Alpha}");
	}

	UFUNCTION()
	private bool QueueShouldProceedToNextPhase()
	{
		// Proceed with the queue when one of the players gets close enough to the boss
		if (Game::GetDistanceFromLocationToClosestPlayer(ActorLocation) < 500)
			return true;
		return false;
	}
}

/**
 * Action Queue Capabilities will only become active if they are at the front of any action queue.
 * They are otherwise the same as normal capabilities, but should not be added to any sheets.
 */
class UExampleActionQueueJumpAttackCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// When the capability deactivates, the action queue will proceed to the next queued action automatically
		if (ActiveDuration > 1.0)
			return true;
		return false;
	}
}

/**
 * Action Queue Capabilities can also override an `OnBecomeFrontOfQueue` to take any parameter struct.
 * This struct is provided when queueing the action for the capability, and sent into the capability when it is at the front.
 */
class UExampleActionQueueTargetedAttackCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FExampleActionQueueTargetedAttackParameters QueueParameters;
	AExampleActionQueueBoss Boss;

	/**
	 * Implementing OnBecomeFrontOfQueue with a struct type will then require those parameters to
	 * be specified when the capability is queued into the action queue.
	 * 
	 * NB: This is automatically networked and called on both sides for capabilities with a NetworkMode.
	 */
	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FExampleActionQueueTargetedAttackParameters Parameters)
	{
		QueueParameters = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<AExampleActionQueueBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// If an action queue capability refuses to activate, the queue will wait until it does
		if (Boss.bAttacksPaused)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// When the capability deactivates, the action queue will proceed to the next queued action automatically
		if (ActiveDuration > 1.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Print(f"Targeting: {QueueParameters.TargetPlayer}");
	}
}

struct FExampleActionQueueTargetedAttackParameters
{
	AHazePlayerCharacter TargetPlayer;
}

/**
 * Action queues can also be set to looping and can provide all the functionality of a TimeLike that way.
 * In this example we implement a curve on top of a Duration action:
 */
class AExample_ActionQueue_TimeLike : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Curve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActionQueue.SetLooping(true);
		ActionQueue.Duration(4.0, this, n"UpdateHeight");
	}

	UFUNCTION()
	private void UpdateHeight(float Alpha)
	{
		float Height = Curve.GetFloatValue(Alpha);
		Print(f"Height value based on curve: {Height}");
	}
}

/**
 * Actions happen when you queue them, and for non-looping action queues will happen once.
 */
class AExample_ActionQueue_StartStop : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	// Reset the queue and play again from the beginning
	void PlayFromStart()
	{
		ActionQueue.Empty();
		ActionQueue.Duration(4.0, this, n"UpdateHeight");
		ActionQueue.Event(this, n"OnCompleted");
	}

	// Stop at the current position by emptying the queue
	void Stop()
	{
		ActionQueue.Empty();
	}

	// Toggle pausing the queue and resuming it later
	void TogglePause()
	{
		if (ActionQueue.IsPaused())
			ActionQueue.SetPaused(false);
		else
			ActionQueue.SetPaused(true);
	}

	UFUNCTION()
	private void UpdateHeight(float Alpha)
	{
		// Use a default smooth curve for the alpha:
		float Height = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);
		Print(f"Height value based on curve: {Height}");
	}

	UFUNCTION()
	private void OnCompleted()
	{
	}
}

/**
 * Looping action queues can also be scrubbed, this is useful to easily implement networking
 * for curve-based movement by scrubbing to the predicted crumb trail time.
 * 
 * NB: Scrubbing is not possible on action queues that contain any Capability actions.
 */
class AExample_ActionQueue_Scrubbed : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Curve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActionQueue.SetLooping(true);
		ActionQueue.Duration(4.0, this, n"UpdateHeight");
	}

	UFUNCTION()
	private void UpdateHeight(float Alpha)
	{
		float Height = Curve.GetFloatValue(Alpha);
		Print(f"Height value based on curve: {Height}");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// This will scrub the action queue to the same predicted crumb trail time on both sides,
		// causing the height value to be synced to the same value in network.
		ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime);
	}
}

/**
 * FlipFlop is not available on Action Queues, but can be implemented trivially by looping and
 * adding a second ReverseDuration action, like this:
 */
class AExample_ActionQueue_FlipFlop : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Curve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActionQueue.SetLooping(true);
		ActionQueue.Duration(4.0, this, n"UpdateHeight");
		ActionQueue.ReverseDuration(4.0, this, n"UpdateHeight");

		// With ReverseDuration, the Alpha value starts at 1 and goes to 0 over the
		// specified duration, allowing FlipFlop to be implemented easily
	}

	UFUNCTION()
	private void UpdateHeight(float Alpha)
	{
		float Height = Curve.GetFloatValue(Alpha);
		Print(f"Height value based on curve: {Height}");
	}
}

/**
 * In cases where using a component is not desirable (for example when inside a capability),
 * you can also initialize and update an FHazeActionQueue directly instead of using a component.
 */
class UExampleCapabilityWithInternalActionQueue : UHazeCapability
{
	FHazeActionQueue ActionQueue;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActionQueue.Initialize(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Queue up some actions:
		ActionQueue.Idle(1);
		ActionQueue.Event(this, n"FirstDelegate");
		ActionQueue.Duration(5.0, this, n"DurationDelegate");
		ActionQueue.Idle(1);
	}

	UFUNCTION()
	private void FirstDelegate()
	{
	}

	UFUNCTION()
	private void DurationDelegate(float Alpha)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActionQueue.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ActionQueue.Update(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("ActionQueue", ActionQueue);
	}
}

/**
 * In certain advanced cases, you might want to run multiple actions at the same time.
 * This can be done with the Parallel() action, which takes multiple subqueues:
 */
local void Example_ParallelActionQueue(AExampleActionQueueBoss ExampleBoss)
{
	// Create two parallel subqueues:
	TArray<FHazeActionQueue> ParallelQueues;
	ParallelQueues.SetNum(2);

	// Actions can be queued as normal:
	// SubQueue 0:
	ParallelQueues[0].Idle(1);
	ParallelQueues[0].Capability(UExampleActionQueueJumpAttackCapability);

	// SubQueue 1:
	FExampleActionQueueTargetedAttackParameters TargetParameters;
	TargetParameters.TargetPlayer = Game::Zoe;
	ParallelQueues[1].Capability(
		UExampleActionQueueTargetedAttackCapability,
		TargetParameters
	);

	// Queue the subqueues onto the boss:
	// Both subqueues will now run at the same time in parallel.
	// The main queue will only proceed once _both_ are finished.
	ExampleBoss.ActionQueue.Parallel(ParallelQueues);
}

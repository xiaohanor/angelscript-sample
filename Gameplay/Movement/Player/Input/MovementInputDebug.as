

namespace MovementInputDebug
{
	struct FDebugData
	{
		FVector Input = FVector::ZeroVector;
		FVector ReplicatedInput = FVector::ZeroVector;
		FVector XAxisDirection = FVector::ZeroVector;
		FVector YAxisDirection = FVector::ZeroVector;
		bool bIsPlaneLocked = false;

		FDebugData()
		{

		}

		FDebugData(UPlayerMovementComponent PlayerMovement)
		{
			bIsPlaneLocked = !PlayerMovement.InputPlaneLock.IsDefaultValue();
			Input = PlayerMovement.GetMovementInput();
			ReplicatedInput = PlayerMovement.GetSyncedMovementInputForAnimationOnly();
		}
	}

	void WriteToTemporalLog(AHazeActor ControllerActor, FInstigator InputInstigator, FDebugData DebugInfo)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(ControllerActor, "Input");

		FVector DrawLocation = ControllerActor.ActorCenterLocation;
		
		TemporalLog
		.Value("Movement;Input Instigator", InputInstigator)
		.DirectionalArrow("Movement;Movement Input", DrawLocation, DebugInfo.Input.GetSafeNormal() * 500, Color = FLinearColor::Yellow)
		.DirectionalArrow("Movement;Animation Input", DrawLocation, DebugInfo.ReplicatedInput.GetSafeNormal() * 500, Color = FLinearColor::Yellow)
		.Value("Movement;Plane Lock", DebugInfo.bIsPlaneLocked)
		;

		FString Controller = "Movement;Control Rotation ";
		if(DebugInfo.bIsPlaneLocked)
		{
			Controller = "Movement;Plane Lock Rotation ";
		}

		TemporalLog.DirectionalArrow(Controller + "Forward", DrawLocation, DebugInfo.XAxisDirection * 600, Color = FLinearColor::Red);
		TemporalLog.DirectionalArrow(Controller + "Right", DrawLocation, DebugInfo.YAxisDirection * 600, Color = FLinearColor::Green);
	}
}
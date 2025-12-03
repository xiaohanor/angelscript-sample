
class UPlayerAirJumpComponent : UActorComponent
{
	UPlayerAirJumpSettings Settings;

	//Is AirJump ready for use
	bool bCanAirJump = true;
	
	// Whether
	bool bKeepLaunchVelocityDuringAirJumpUntilLanded = false;
	float KeepLaunchVelocityUntilTime = 0.0;

	//Temp Anim Bool
	bool bPerformedDoubleJump = false;

	TArray<FAirJumpAutoTarget> AutoTargets;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerAirJumpSettings::GetSettings(Cast<AHazeActor>(Owner));
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void AddAutoTarget(FAirJumpAutoTarget Target)
	{
		for (int i = AutoTargets.Num() - 1; i >= 0; --i)
		{
			if (AutoTargets[i].Component == Target.Component)
			{
				AutoTargets[i] = Target;
				return;
			}
		}

		AutoTargets.Add(Target);
	}

	void RemoveAutoTarget(USceneComponent Point)
	{
		for (int i = AutoTargets.Num() - 1; i >= 0; --i)
		{
			if (AutoTargets[i].Component == Point)
				AutoTargets.RemoveAtSwap(i);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}
}

struct FAirJumpAutoTarget
{
	USceneComponent Component;
	FVector LocalOffset;

	// NB: Height difference is signed, so being below the target point gives a negative
	bool bCheckHeightDifference = false;
	float MinHeightDifference = 0.0;
	float MaxHeightDifference = 0.0;

	bool bCheckFlatDistance = false;
	float MinFlatDistance = 0.0;
	float MaxFlatDistance = 0.0;

	bool bCheckInputAngle = false;
	float MaxInputAngle = 0.0;
}
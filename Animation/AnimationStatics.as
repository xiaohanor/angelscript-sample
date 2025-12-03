
/*
 * This file should contain generic helper functions that can be used in an AnimInstance or ABP
*/


namespace HazeAnimation {
	// (1/60 = ~0.0167) Minimum time required to be left for an animation to be considered not done.
	const float ANIMATION_MIN_TIME = 1.0/60.0;
}


namespace HazePhysicalAnimationProfileNames
{
	const FName Tail = n"Tail";

}

// Anim Param Tags commonly used
namespace HazeAnimParamTags
{
	const FName SkipMovementStart = n"SkipMovementStart";
	const FName MovementBlendTime = n"MovementBlendTime";
}


// -----------------------------
// 		Inverse Kinematics
// ------------------------------

UFUNCTION(BlueprintPure)
mixin FRotator GetSlopeRotationForAnimation(UHazeMovementComponent MoveComp)
{
	return FRotator::MakeFromZX(MoveComp.HazeOwner.ActorTransform.InverseTransformVector(MoveComp.GetGroundContact().ImpactNormal), FVector::ForwardVector);
}


// -----------------------------
// 			Misc
// ------------------------------

/** Used for the `CheckValueChangedAndSetBool()` function */
enum EHazeCheckBooleanChangedDirection
{
	BothWays,
	TrueToFalse,
	FalseToTrue,
}

/**
 * Check if a boolean changes value, then set the `bOutBoolean` to `bNewValue`.
 * @param `bOutBoolean` - Pointer to the current boolean
 * @param `bNewValue` - The new value to set bOutBoolean with.
 * @param `TriggerDirection` - Limit the function to e.g. only return `True` when `bOutBoolean` changes from `False` to `True`
 * 
 * @returns a boolean if the value has changed (based on the TriggerDirection)
 */
UFUNCTION()
bool CheckValueChangedAndSetBool(bool& bOutBoolean, bool bNewValue, EHazeCheckBooleanChangedDirection TriggerDirection = EHazeCheckBooleanChangedDirection::BothWays)
{
	const bool bHasValueChanged = (bOutBoolean != bNewValue);
	bOutBoolean = bNewValue;
		
	if (TriggerDirection == EHazeCheckBooleanChangedDirection::FalseToTrue)
		return bHasValueChanged && bOutBoolean;
	else if (TriggerDirection == EHazeCheckBooleanChangedDirection::TrueToFalse)
		return bHasValueChanged && !bOutBoolean;
	
	return bHasValueChanged;
}

enum EHazeCardinalDirection
{
	Forward,
	Left,
	Right,
	Backward,
}

enum EAnimHitPitch
{
	Up,
	Center,
	Down,	
}

/** 
* Get cardinal directions from a float (Forward, Backward, Left, Right)
* @param `Angle` - Expecting a value from 180 to -180
*/
UFUNCTION(BlueprintPure)
EHazeCardinalDirection AngleToCardinalDirection(float Angle)
{
	if (Angle > -45.0 && Angle < 45.0)
		return EHazeCardinalDirection::Forward;
	else if (Angle > 135.0 || Angle < -135.0)
		return EHazeCardinalDirection::Backward;
	else if (Angle < 0.0)
		return EHazeCardinalDirection::Left;
	else
		return EHazeCardinalDirection::Right;
}


/** 
* Get cardinal directions for a vector in respect to the given actors rotation
* @param `Actor` - The actor in relation to whom the direction is calculated
* @param `WorldDirection` - If this vector aligns with actors forward, we get a Forward direction etc.
*/
UFUNCTION(BlueprintPure)
EHazeCardinalDirection CardinalDirectionForActor(AActor Actor, FVector WorldDirection)
{
	FVector Dir = WorldDirection.IsNormalized() ? WorldDirection : WorldDirection.GetSafeNormal();
	
	float FwdDot = Actor.ActorForwardVector.DotProduct(Dir);
	if (FwdDot > 0.707)
		return EHazeCardinalDirection::Forward;
	if (FwdDot < -0.707)
		return EHazeCardinalDirection::Backward;
	
	float RightDot = Actor.ActorRightVector.DotProduct(Dir);
	if (RightDot > 0.0)
		return EHazeCardinalDirection::Right;
	return EHazeCardinalDirection::Left;
}




UFUNCTION(BlueprintPure)
mixin FVector2D CalculatePlayerAimAngles(AHazePlayerCharacter Player)
{
	if(Player == nullptr)
		return FVector2D::ZeroVector;

	return CalculateAimAngles(Player.GetViewRotation().ForwardVector, Player.ActorTransform);
}


/** 
 * This function will calculate aim angles, however it will use a buffer around 180 degrees for yawing
 * Without this buffer, if you're aiming straight behind it will constantly flicker between -180 and 180
 *
 * The buffer size means that if the angle is between 180 +- buffersize, it will keep the polarity of the previous angle
 * So, for example, if the buffer is 5, and our previous angle is 180,
 * we can go up all the way to 185 degrees before switching to -175 
 */
UFUNCTION(BlueprintPure)
mixin FVector2D CalculatePlayerAimAnglesBuffered(AHazePlayerCharacter Player, FVector2D Previous, float BufferSize = 5.0)
{
	if(Player == nullptr)
		return FVector2D::ZeroVector;

	FVector2D NewAngles = Player.CalculatePlayerAimAngles();

	// Check if we're within the buffer...
	if (NewAngles.X < -180.0 + BufferSize || NewAngles.X > 180.0 - BufferSize)
	{
		// We're within the buffer, so keep the sign of the previous angles
		if (Previous.X > 0 && NewAngles.X < 0)
			NewAngles.X += 360.0; // Convert sign
		else if (Previous.X < 0 && NewAngles.X > 0)
			NewAngles.X -= 360.0; // Convert sign
	}

	return NewAngles;
}

UFUNCTION(BlueprintPure)
FVector2D CalculateAimAngles(FVector AimDirection, FTransform ActorTransform)
{
	FVector2D Result;

	// Calculate Pitch
	float PitchDot = AimDirection.DotProduct(ActorTransform.Rotation.UpVector);
	Result.Y = Math::RadiansToDegrees(Math::Asin(PitchDot));

	// Calculate Yaw
	float ForwDot = AimDirection.DotProduct(ActorTransform.Rotation.ForwardVector);
	float RightDot = AimDirection.DotProduct(ActorTransform.Rotation.RightVector);
	Result.X = Math::RadiansToDegrees(Math::Atan2(RightDot, ForwDot));

	return Result;
}

UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe))
bool IsValueBetween(float Value, float Min, float Max)
{
	return Value > Min && Value < Max;
}

UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe), DisplayName = "GetAnimNotifyStateStartTime")
float BP_GetAnimNotifyStateStartTime(FHazePlaySequenceData SequenceData, TSubclassOf<UAnimNotifyState> NotifyClass)
{
	if (SequenceData.Sequence == nullptr)
		return 0.0;
	return SequenceData.Sequence.GetAnimNotifyStateStartTime(NotifyClass);
}

mixin float GetAnimNotifyStateStartTime(UAnimSequenceBase Sequence, TSubclassOf<UAnimNotifyState> NotifyClass)
{
	if (Sequence == nullptr)
		return 0.0;

	if (!NotifyClass.IsValid())
		return 0.0;

	TArray<FHazeAnimNotifyStateGatherInfo> NotifyInfo;
	if (Sequence.GetAnimNotifyStateTriggerTimes(NotifyClass, NotifyInfo) && (NotifyInfo.Num() > 0))
		return NotifyInfo[0].TriggerTime;

	return 0.0;
}

UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe), DisplayName = "GetAnimNotifyStateEndTime")
float BP_GetAnimNotifyStateEndTime(FHazePlaySequenceData SequenceData, TSubclassOf<UAnimNotifyState> NotifyClass)
{
	if (SequenceData.Sequence == nullptr)
		return 0.0;
	return SequenceData.Sequence.GetAnimNotifyStateEndTime(NotifyClass);
}

mixin float GetAnimNotifyStateEndTime(UAnimSequenceBase Sequence, TSubclassOf<UAnimNotifyState> NotifyClass)
{
	if (Sequence == nullptr)
		return 0.0;

	if (!NotifyClass.IsValid())
		return 0.0;

	TArray<FHazeAnimNotifyStateGatherInfo> NotifyInfo;
	if (Sequence.GetAnimNotifyStateTriggerTimes(NotifyClass, NotifyInfo) && (NotifyInfo.Num() > 0))
		return NotifyInfo.Last().TriggerTime + NotifyInfo.Last().Duration;

	return 0.0;
}

UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe), DisplayName = "GetAnimNotifyTime")
float BP_GetAnimNotifyTime(FHazePlaySequenceData SequenceData, TSubclassOf<UAnimNotify> NotifyClass)
{
	if (SequenceData.Sequence == nullptr)
		return 0.0;
	return SequenceData.Sequence.GetAnimNotifyTime(NotifyClass);
}

mixin float GetAnimNotifyTime(UAnimSequenceBase Sequence, TSubclassOf<UAnimNotify> NotifyClass)
{
	if (Sequence == nullptr)
		return 0.0;

	if (!NotifyClass.IsValid())
		return 0.0;

	TArray<float32> NotifyInfo;
	if (Sequence.GetAnimNotifyTriggerTimes(NotifyClass, NotifyInfo) && (NotifyInfo.Num() > 0))
		return NotifyInfo[0];

	return 0.0;
}

void SetAnimBlendTimeToMovement(AHazeActor Character, float BlendTime)
{
	Character.SetAnimFloatParam(HazeAnimParamTags::MovementBlendTime, BlendTime);
}


float CalculateAnimationBankingValue(AHazeActor Actor, FQuat& CachedActorQuat, float DeltaTime, float MaxTurnSpeed) 
{
	if (DeltaTime == 0)
		return 0;

	const float PreviousYaw = Math::RadiansToDegrees(CachedActorQuat.GetTwistAngle(Actor.ActorUpVector));
	const float CurrentYaw = Math::RadiansToDegrees(Actor.ActorQuat.GetTwistAngle(Actor.ActorUpVector));
	const float DeltaYaw = Math::FindDeltaAngleDegrees(PreviousYaw, CurrentYaw);
	float ReturnValue = (DeltaYaw / DeltaTime) / MaxTurnSpeed;
	CachedActorQuat = Actor.ActorQuat;
	return ReturnValue;
}
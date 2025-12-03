enum EPigRainbowFartResponseRotationAxis
{
	Pitch,
	Yaw,
	Roll
}

enum EPigRainbowFartResponseType
{
	Nothing,
	Movement
}

enum EPigRainbowFartMovementResponseType
{
	Rotation,
	Wiggle
}

struct FPigRainbowFartMovementResponseData
{
	UPROPERTY(EditAnywhere)
	EPigRainbowFartMovementResponseType MovementType = EPigRainbowFartMovementResponseType::Rotation;

	UPROPERTY(EditAnywhere)
	float Duration = 2.5;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 20.0;

	UPROPERTY(EditAnywhere)
	float WiggleMaxAngle = 15.0;

	UPROPERTY()
	EPigRainbowFartResponseRotationAxis RotationAxis = EPigRainbowFartResponseRotationAxis::Yaw;

	FRotator GetRotatorWithAmount(const float Amount) const
	{
		switch (RotationAxis)
		{
			case EPigRainbowFartResponseRotationAxis::Pitch:	return FRotator(Amount, 0, 0);
			case EPigRainbowFartResponseRotationAxis::Yaw:		return FRotator(0, Amount, 0);
			case EPigRainbowFartResponseRotationAxis::Roll:		return FRotator(0, 0, Amount);
		}
	}

	FVector GetRotationAxisForComponent(USceneComponent Component) const
	{
		switch (RotationAxis)
		{
			case EPigRainbowFartResponseRotationAxis::Pitch:	return Component.RightVector;
			case EPigRainbowFartResponseRotationAxis::Yaw:		return Component.UpVector;
			case EPigRainbowFartResponseRotationAxis::Roll:		return Component.ForwardVector;
		}
	}

	FVector GetCrossRotationAxisForComponent(USceneComponent Component) const
	{
		switch (RotationAxis)
		{
			case EPigRainbowFartResponseRotationAxis::Pitch:	return Component.ForwardVector;
			case EPigRainbowFartResponseRotationAxis::Yaw:		return Component.RightVector;
			case EPigRainbowFartResponseRotationAxis::Roll:		return Component.UpVector;
		}
	}
}

class UPigRainbowFartResponseComponent : UHazeMovablePlayerTriggerComponent
{
	UPROPERTY(EditAnywhere)
	EPigRainbowFartResponseType ResponseType;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = ("ResponseType == EPigRainbowFartResponseType::Movement"), EditConditionHides))
	FPigRainbowFartMovementResponseData MovementResponseData;

	UFUNCTION(BlueprintOverride)
	bool CanTriggerForPlayer(AHazePlayerCharacter Player) const
	{
		UPlayerPigRainbowFartComponent FartComponent = UPlayerPigRainbowFartComponent::Get(Player);
		if (FartComponent == nullptr)
			return false;

		if (!FartComponent.IsFarting())
			return false;

		return true;
	}
}
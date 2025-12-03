class UIslandOverseerDynamicForcedTargetPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;

	UIslandOverseerDynamicForcedTargetPlayerComponent ForcedTargetComp;
	float MaxDistanceOffset = 2500;
	float AimSpeed = 4500;
	float ReturnSpeed = 3500;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ForcedTargetComp = UIslandOverseerDynamicForcedTargetPlayerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);		

		for(AIslandOverseerDynamicForcedTarget Target : ForcedTargetComp.Targets)
		{
			if(Player.IsUsingGamepad())
			{
				if(Input.X < SMALL_NUMBER && Input.X > -SMALL_NUMBER)
				{
					float Delta = ReturnSpeed * DeltaTime;
					if(Target.DistanceOffset > 0)
						Delta *= -1;
					Target.DistanceOffset += Delta;
				}
				else
					Target.DistanceOffset = Input.X * MaxDistanceOffset;
			}
			else
			{
				if(!IsActioning(ActionNames::WeaponFire))
					Target.DistanceOffset = 0; // Should we be doing this reset? Should there be a cooldown before it resets?
				else
					Target.DistanceOffset = Math::Clamp(Target.DistanceOffset + Input.X * AimSpeed * DeltaTime, -MaxDistanceOffset, MaxDistanceOffset);
			}

			FVector BaseLocation;
			if(Target.AttachParentActor == nullptr)
				BaseLocation = Target.ActorLocation;
			else
				BaseLocation = Target.AttachParentActor.ActorLocation;

			FVector Direction = Target.ForcedTargetPlayer.ViewRotation.RightVector;
			FVector Offset = Target.ForcedTargetPlayer.ActorLocation - BaseLocation;
			float Distance = Offset.DotProduct(Direction);
			FVector Location = BaseLocation + Direction * (Distance + Target.DistanceOffset);
			Target.ActorLocation = Location;
		}
	}
}
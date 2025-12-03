

/**
 * Intended to be spawned, apply forces on over time and then get destroyed. 
 */

UCLASS(Abstract)
class ABaseImpactFieldSystemActor : ABaseFieldSystemActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	default ActorScale3D = FVector::OneVector*2.0;

	UPROPERTY(Category = "Haze Chaos Destruction")
	float StrainMagnitude = 10000000.0;

	UPROPERTY(Category = "Haze Chaos Destruction")
	float ForceMagnitude = 2000000.0;

	UPROPERTY(Category = "Haze Chaos Destruction")
	float TorqueMagnitude = 2000000.0;

	UPROPERTY(DefaultComponent, Category = "Haze Chaos Destruction")
	USphereComponent SphereCollision;
	default SphereCollision.SphereRadius = 200;

	// used to set the vari
	UPROPERTY(DefaultComponent)
	UUniformInteger UniformInt;

	UPROPERTY(DefaultComponent)
	URadialFalloff Culling_SpeedThreshold;

	UPROPERTY(DefaultComponent)
	URadialFalloff Culling_DistanceThreshold;

	UPROPERTY(DefaultComponent)
	UCullingField CullingField;
	
	UPROPERTY(DefaultComponent)
	URadialVector ForceDirection;

	UPROPERTY(DefaultComponent)
	URadialFalloff ForceBounds;

	UPROPERTY(DefaultComponent)
	UOperatorField ForceOperator;

	UPROPERTY(DefaultComponent)
	URadialFalloff StrainBounds;

	UPROPERTY(DefaultComponent)
	URandomVector TorqueDirection;

	UPROPERTY(DefaultComponent)
	UUniformVector TorqueMultiplier;

	UPROPERTY(DefaultComponent)
	UOperatorField TorqueOperator;

	UPROPERTY(DefaultComponent)
	URadialFalloff TorqueBounds;

	UPROPERTY(DefaultComponent)
	UOperatorField TorqueOperator_2;
	
	/** Changes how strong and wide the force are */
	UFUNCTION(BlueprintCallable, Category = "Haze Chaos Destruction")
	void ApplyFieldForceSettings(float Force, float Torque, float Radius, float BreakingStrain = 10000000)
	{
		SphereCollision.SetSphereRadius(Radius);
		StrainMagnitude = BreakingStrain;
		ForceMagnitude = Force;
		TorqueMagnitude = Torque;
	}

	/**
	 * Emits one-shot forces and torques to pieces that overlap this sphere. 
	 * The linear forces are omnidirection but can be constrained to a direction
	 * if the OptionalDirection is set to something other then 0 Vector.
	 */
	UFUNCTION(BlueprintCallable, Category = "Haze Chaos Destruction", meta = (AdvancedDisplay = OptionalDirection))
	void ApplyFieldForceAtLocation(FVector InLocation, FVector OptionalDirection = FVector(0))
	{
		SetActorLocation(InLocation);
		ApplyFieldForce(OptionalDirection);
	}

	/**
	 * Emits one-shot forces and torques to pieces that overlap this sphere. 
	 * The linear forces are omnidirection but can be constrained to a direction
	 * if the OptionalDirection is set to something other then 0 Vector.
	 */
	UFUNCTION(BlueprintCallable, Category = "Haze Chaos Destruction", meta = (AdvancedDisplay = OptionalDirection))
	void ApplyFieldForce(FVector OptionalDirection = FVector::ZeroVector)
	{
		// note that this will affect PhysicsAnimations as well
		// ApplyDynamic();

		// ApplyStrain();
		// ApplySleep();

		// break up clustered geometry collection, 
		// by applying strain, before forces can be applied
		ApplyStrain();
		ApplyLinearForce(OptionalDirection);
		ApplyTorque();

		// Debug::DrawDebugSphere(
		// 	SphereCollision.GetWorldLocation(),
		// 	SphereCollision.GetScaledSphereRadius(),
		// 	Duration = 1, 
		// 	LineColor = FLinearColor::Red,
		// 	Thickness = 10.0
		// );
	}

	void ApplyGlobalStrainAtLocation(FVector InLocation)
	{
		SetActorLocation(InLocation);
		ApplyDynamic();
		ApplyGlobalStrain();
	}

	void ApplyGlobalStrain()
	{
		StrainBounds = StrainBounds.SetRadialFalloff(
			StrainMagnitude,
			0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_FallOff_None
		);

		FieldSystemComponent.ApplyPhysicsField(
			true,
			EFieldPhysicsType::Field_ExternalClusterStrain,
			nullptr, 
			StrainBounds
		);

		// FieldSystemComponent.ApplyPhysicsField(
		// 	true,
		// 	EFieldPhysicsType::Field_InternalClusterStrain,
		// 	nullptr, 
		// 	StrainBounds
		// );

	}

	void ApplyCulledStrain()
	{
		StrainBounds = StrainBounds.SetRadialFalloff(
			StrainMagnitude,
			0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_FallOff_None
		);

		// distance
		Culling_DistanceThreshold = Culling_DistanceThreshold.SetRadialFalloff(
			1.0, 
			0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_FallOff_None
		);

		CullingField.SetCullingField(
			Culling_DistanceThreshold,
			StrainBounds,
			EFieldCullingOperationType::Field_Culling_Inside
		);

		FieldSystemComponent.ApplyPhysicsField(
			true,
			EFieldPhysicsType::Field_ExternalClusterStrain,
			nullptr, 
			CullingField
		);

		// FieldSystemComponent.ApplyPhysicsField(
		// 	true,
		// 	EFieldPhysicsType::Field_InternalClusterStrain,
		// 	nullptr, 
		// 	CullingField
		// );

	}

	void ApplyStrain()
	{
		ApplyGlobalStrain();
		ApplyCulledStrain();
	}

	void ApplyLinearForce(FVector OptionalDirection = FVector::ZeroVector)
	{
		// determine direction and magnitude of the force
		if(OptionalDirection.IsZero())
		{
			ForceDirection = ForceDirection.SetRadialVector(
				ForceMagnitude,
				SphereCollision.GetWorldLocation()
			);
		}
		else
		{
			ForceDirection = ForceDirection.SetRadialVector(
				ForceMagnitude,
				GetActorLocation() - OptionalDirection*200.0
			);
		}

		// limit the area where the force is applied
		ForceBounds = ForceBounds.SetRadialFalloff(
			1.0, 0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_FallOff_None
		);

		// combine fields with operator.
		ForceOperator = ForceOperator.SetOperatorField(
			1.0,
			ForceBounds,
			ForceDirection,
			EFieldOperationType::Field_Multiply
		);

		// // apply that bad boy
		FieldSystemComponent.ApplyPhysicsField(
			true,
			EFieldPhysicsType::Field_LinearForce,
			nullptr,
			ForceOperator
		);

		///////////////////////////////////
		//

		// distance
		Culling_DistanceThreshold = Culling_DistanceThreshold.SetRadialFalloff(
			1.0, 
			0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_FallOff_None
		);

		CullingField.SetCullingField(
			Culling_DistanceThreshold,
			ForceOperator,
			EFieldCullingOperationType::Field_Culling_Outside
		);

		//
		///////////////////////////////////

		// apply that bad boy
		// FieldSystemComponent.ApplyPhysicsField(
		// 	true,
		// 	EFieldPhysicsType::Field_LinearForce,
		// 	nullptr,
		// 	CullingField
		// );
	}

	void ApplyTorque()
	{
		// start with random vector
		TorqueDirection = TorqueDirection.SetRandomVector(TorqueMagnitude);

		// increase rotation per axis
		TorqueMultiplier = TorqueMultiplier.SetUniformVector(1.0, FVector(4.0, 4.0, 10.0));

		// combine
		TorqueOperator = TorqueOperator.SetOperatorField(
			1.0, 
			TorqueMultiplier, 
			TorqueDirection, 
			EFieldOperationType::Field_Multiply
		);

		TorqueBounds = TorqueBounds.SetRadialFalloff(
			5.0,
			0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_Falloff_Linear
		);

		// combine
		TorqueOperator_2 = TorqueOperator_2.SetOperatorField(
			1.0, 
			TorqueBounds,
			TorqueOperator,
			EFieldOperationType::Field_Multiply
		);

		// // apply
		// FieldSystemComponent.ApplyPhysicsField(
		// 	true,
		// 	EFieldPhysicsType::Field_AngularTorque,
		// 	nullptr,
		// 	TorqueOperator_2
		// );

		///////////////////////////////////
		//

		// distance
		Culling_DistanceThreshold = Culling_DistanceThreshold.SetRadialFalloff(
			1.0, 
			0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_FallOff_None
		);

		CullingField.SetCullingField(
			Culling_DistanceThreshold,
			TorqueOperator_2,
			EFieldCullingOperationType::Field_Culling_Outside
		);

		//
		///////////////////////////////////

		// apply
		FieldSystemComponent.ApplyPhysicsField(
			true,
			EFieldPhysicsType::Field_AngularTorque,
			nullptr,
			CullingField
		);
	}

	void UpdateCullingField()
	{
		// speed
		Culling_SpeedThreshold = Culling_SpeedThreshold.SetRadialFalloff(
			1000000000000.0, // below this speed
			0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_FallOff_None
		);

		// distance
		Culling_DistanceThreshold = Culling_DistanceThreshold.SetRadialFalloff(
			1.0, 
			0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_FallOff_None
		);

		CullingField.SetCullingField(
			Culling_DistanceThreshold,
			Culling_SpeedThreshold,
			EFieldCullingOperationType::Field_Culling_Outside
		);

	}

	void ApplyKill()
	{
		UpdateCullingField();

		FieldSystemComponent.ApplyPhysicsField(
			true,
			EFieldPhysicsType::Field_Kill,
			nullptr,
			CullingField
		);

	}

	void ApplyDisable()
	{
		UpdateCullingField();

		FieldSystemComponent.ApplyPhysicsField(
			true,
			EFieldPhysicsType::Field_DisableThreshold,
			nullptr,
			CullingField
		);

	}

	void ApplySleep()
	{
		UpdateCullingField();

		FieldSystemComponent.ApplyPhysicsField(
			true,
			EFieldPhysicsType::Field_SleepingThreshold,
			nullptr,
			CullingField
		);

		//////////////////////////////////////////////////////

		UniformInt.SetUniformInteger(
			int(EObjectStateTypeEnum::Chaos_Object_Sleeping)
		);		

		// distance
		Culling_DistanceThreshold = Culling_DistanceThreshold.SetRadialFalloff(
			1.0, 
			0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_FallOff_None
		);

		CullingField.SetCullingField(
			Culling_DistanceThreshold,
			UniformInt,
			EFieldCullingOperationType::Field_Culling_Outside
		);

		FieldSystemComponent.ApplyPhysicsField(
			true,
			EFieldPhysicsType::Field_DynamicState,
			nullptr,
			CullingField
		);
	}

	void ApplyDynamic()
	{
		UniformInt.SetUniformInteger(
			int(EObjectStateTypeEnum::Chaos_Object_Dynamic)
		);		

		// distance
		Culling_DistanceThreshold = Culling_DistanceThreshold.SetRadialFalloff(
			1.0, 
			0.0, 1.0, 0.0,
			SphereCollision.ScaledSphereRadius,
			SphereCollision.GetWorldLocation(),
			EFieldFalloffType::Field_FallOff_None
		);

		CullingField.SetCullingField(
			Culling_DistanceThreshold,
			UniformInt,
			EFieldCullingOperationType::Field_Culling_Outside
		);

		//UpdateCullingField();

		FieldSystemComponent.ApplyPhysicsField(
			true,
			EFieldPhysicsType::Field_DynamicState,
			nullptr,
			CullingField
		);

	}

}
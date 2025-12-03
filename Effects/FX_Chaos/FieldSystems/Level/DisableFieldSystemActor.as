
/**
 * Will disable chunks whose center of mass intersect the volume
 */

class ADisableFieldSystemActor : ABaseFieldSystemActor
{
	// Culling fields restrain an operation to the defined volume
	UPROPERTY(DefaultComponent)
	UCullingField CullingField;

	// used to set the vari
	UPROPERTY(DefaultComponent)
	UUniformInteger UniformInt;

	// for the velocity check
	UPROPERTY(DefaultComponent)
	UBoxFalloff BoxFalloff_Velocity;

	// for the velocity check
	UPROPERTY(DefaultComponent)
	UBoxFalloff BoxFalloff_Culling;

	// @TODO: replace box with plane
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BoxMesh;
	default BoxMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default BoxMesh.SetCollisionProfileName(n"NoCollision", false);

	UPROPERTY(EditAnywhere)
	float VelocityMagnitudeThreshold = 500000.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ApplyDisableField();
	}

	/**
	 * Disable Fields vary from Sleep fields in that disabled nodes can no longer be 
	 * reactivated by collisions, making them very cheap during simulation. They can, 
	 * however, be reactivated by other fields. This Box approach enables you to 
	 * contain the effect to a specific region. A cheaper approach is to use a Plane 
	 * variant - use this if you are able to direct this behaviour at a 
	 * consistent height throughout an entire level.
	 * 
	 */
	void ApplyDisableField()
	{
		/**
		 * If a rigid body passes into this box while travelling below this 
		 * threshold (velocity magnitude in cm/s), Disable.
		 */
		BoxFalloff_Velocity.SetBoxFalloff(
			VelocityMagnitudeThreshold,
			0.0, 1.0, 0.0,
			BoxMesh.GetWorldTransform(),
			EFieldFalloffType::Field_FallOff_None
		);

		/**
		 * When using a Disable Threshold, Sleep Threshold, or Kill field, it is critical that we 
		 * apply culling outside of it. Since the outside value is 0 by default, failing to cull this 
		 * field would stomp any other such fields in the map, effectively telling them to ignore 
		 * any other Threshold set outside of this one.
		 */
		BoxFalloff_Culling.SetBoxFalloff(
			1.0,
			0.0, 1.0, 0.0,
			BoxMesh.GetWorldTransform(),
			EFieldFalloffType::Field_FallOff_None
		);

		CullingField.SetCullingField(
			BoxFalloff_Culling,
			BoxFalloff_Velocity,
			EFieldCullingOperationType::Field_Culling_Outside
		);

		FieldSystemComponent.ApplyPhysicsField(
			true,
			EFieldPhysicsType::Field_DisableThreshold,
			nullptr,
			CullingField
		);
	}


}
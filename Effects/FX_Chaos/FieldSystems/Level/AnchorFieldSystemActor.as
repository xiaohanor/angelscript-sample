
class AAnchorFieldSystemActor : ABaseFieldSystemActor
{
	// Culling fields restrain an operation to the defined volume
	UPROPERTY(DefaultComponent)
	UCullingField CullingField;

	UPROPERTY(DefaultComponent)
	UUniformInteger UniformInt;

	UPROPERTY(DefaultComponent)
	UBoxFalloff BoxFalloff;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BoxMesh;
	default BoxMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default BoxMesh.SetCollisionProfileName(n"NoCollision", false);

	/**
	* we'll register the field commands here. The affected GeometryCollection will then
	* have a reference to this actor in it's InitFields Array and init these fields when rdy. 
	* 
	* This setup ensures that commands are executed in the correct order.
	*/
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ApplyStaticField();
	}

	/**
	* We are assuming that the GeometryCollection is gonna set its state into Dynamic.
	* We'll then use the Culling volume to find pieces outside the volume and set them
	* to Dynamic. 
	*/
	void ApplyStaticField()
	{
		// clear old ones
		FieldSystemComponent.ResetFieldSystem();
		
		// define the anchor field region
		BoxFalloff = BoxFalloff.SetBoxFalloff(
			1.0,
			1.0,
			1.0,
			0.0,
			BoxMesh.GetWorldTransform(),
			EFieldFalloffType::Field_FallOff_None
		);

		// flag that the chunks inside the volume should be static
		UniformInt = UniformInt.SetUniformInteger(int(EObjectStateTypeEnum::Chaos_Object_Static));

		// setup the culling field params
		CullingField = CullingField.SetCullingField(
			BoxFalloff,
			UniformInt,
			EFieldCullingOperationType::Field_Culling_Outside
		);

		/**
		 * Reigster the construction field here. The geoCollection will then grab a reference 
		 * to this actor, copy over the commands, and execute it on that actors side - before
		 * anything is simulated.
		 */
		FieldSystemComponent.AddFieldCommand(
			true,
			EFieldPhysicsType::Field_DynamicState,
			nullptr,
			CullingField
		);
	}

}

namespace ExampleMovement
{

	class UExampleMovementCapability : UHazeCapability
	{
		// This should handle pre movement stuff
		default TickGroup = EHazeTickGroup::BeforeMovement;

		// This should handle movement that comes from an external part
		// ex; interactions
		default TickGroup = EHazeTickGroup::InfluenceMovement;

		// This should handle movement that responds to actions
		// ex; jump dash etc...
		default TickGroup = EHazeTickGroup::ActionMovement;

		// This is the main tickgroup and should handle all the regular movement
		// ex; ground move, air move... etc
		default TickGroup = EHazeTickGroup::Movement;

		// This should handle finalizing movement and cleaning up
		default TickGroup = EHazeTickGroup::LastMovement;
		

		UHazeMovementComponent MovementComponent;
		USteppingMovementData Movement;

		UFUNCTION(BlueprintOverride)
		void Setup()
		{
			/** Start by getting the movement component from the owner */
			MovementComponent = UHazeMovementComponent::Get(Owner);

			/** Then define how you want this capability to move.
			* In this case, we use a stepping resolver.
			* Others like, sweeping, teleporting or custom can also be used.
			*/
			Movement = MovementComponent.SetupSteppingMovementData();
		}
		
		UFUNCTION(BlueprintOverride)
		bool ShouldActivate() const
		{
			/** Every movement capability should always validate if any other movement capability
			* has already performed a move.
			*/
			if(MovementComponent.HasMovedThisFrame())
				return false;

			return true;
		}

		UFUNCTION(BlueprintOverride)
		bool ShouldDeactivate() const
		{
			/** Every movement capability should always validate if any other movement capability
			* has already performed a move.
			*/
			if(MovementComponent.HasMovedThisFrame())
				return true;

			return false;
		}


		UFUNCTION(BlueprintOverride)
		void TickActive(float DeltaTime)
		{
			/** First, we prepare the move data.
			* This is also the place to add a custom world up
			* if that is what we want for this frame.
			* The 'PrepareMove' need to be validated because of network.
			*/
			if(MovementComponent.PrepareMove(Movement))
			{
				/** After the movement has been prepared.
				* You fill it with how you want to move this frame.
				* This can be done using varius functions
				*/


				/** Creates a delta move from a velocity */
				Movement.AddVelocity(FVector(1000, 0, 0));

				/** Creates a delta move */
				Movement.AddDelta(FVector(1000 * DeltaTime, 0, 0));

				/** Apply gravity movement. This is just the acceleration part.
				* If you want to add gravity, you should also include the current vertical velocity
				*/
				Movement.AddGravityAcceleration();

				/** Adds the current vertical velocity that the owner has */
				Movement.AddOwnerVerticalVelocity();

				/** Apply the wanted rotation. */
				Movement.SetRotation(FRotator(0, 43, 0));


				/** When you have added everything to your movedata
				* Apply the movement into the movement component.
				* This is the part where the resolver takes over.
				*/
				MovementComponent.ApplyMove(Movement);
			}
		}

		/**
		 * Some settings have been added to the movement component from external system.
		 * These settings are always a request. It is the actual capabilty that decides how to move.
		 * For example, adding impulse. This could be done from an external system.
		 * But the impulse movement is not actually added until the movement capability
		 * applies the impulse
		 */
		void ExampleExternalSettings()
		{
			/** Some parts of the movement comes from other capabilities.
			* These functions are added to the actor instead of the movement component 
			* The reason for this is, so we can modify these types of data without
			* having to change the entire movement system.
			*/
			Owner.ApplyMovementInput(FVector::ForwardVector, this);
			
			/** You would the read this from the movement component
			* where you create your move
			*/
			FVector MovementInput = MovementComponent.GetMovementInput();


			/** The target facing rotation is where you would like actor to face */
			Owner.SetMovementFacingDirection(FVector::ForwardVector);

			/** This would be read from the movmenet component */
			FQuat FacingRotation = MovementComponent.GetTargetFacingRotationQuat();

			/** Or applied on the movement */
			Movement.InterpRotationToTargetFacingRotation(10);
		}
	}

}
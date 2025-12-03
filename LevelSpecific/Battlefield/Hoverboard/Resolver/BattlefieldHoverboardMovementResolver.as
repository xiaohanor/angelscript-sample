class UBattlefieldHoverboardMovementResolver : USteppingMovementResolver
{
	default RequiredDataType = USteppingMovementData;

	FMovementDelta ProjectMovementUponImpact(FMovementResolverState& State, FMovementDelta DeltaState, EMovementIterationDeltaStateType DeltaStateType,
											 FMovementHitResult Impact, FMovementHitResult GroundedState) const override
	{
		const bool bIsLeavingGround = IsLeavingGround();
		const bool bActorIsGrounded = !bIsLeavingGround && GroundedState.IsWalkableGroundContact();
		const bool bHitCanBeGround = !bIsLeavingGround && Impact.IsWalkableGroundContact();

		if(bActorIsGrounded)
		{
			// on grounded impacts, we redirect the delta without any loss
			if(bHitCanBeGround)
			{		
				FVector ImpactNormal = Impact.Normal;
			
				// If we are on edges, we use the impact normal instead to not get sucked down
				//if(Impact.IsOnAnEdge() && Impact.EdgeResult.bIsOnEmptySideOfLedge)
				if(IsLeavingEdge(Impact))
				{
					if(Impact.EdgeResult.OverrideRedirectNormal.IsNearlyZero())
						ImpactNormal = Impact.ImpactNormal;
					else
						ImpactNormal = Impact.EdgeResult.OverrideRedirectNormal;
				}
	
				FMovementDelta ConstrainedDeltaState = DeltaState;

				// On grounded impacts, we remove the vertical part
				// Its important that the vertical part is removed first, else that part will be redirected
				// to follow the ground on slopes
				ConstrainedDeltaState = ConstrainedDeltaState.GetHorizontalPart(CurrentWorldUp);

				// We keep the velocity constrained to the actual impact normal
				// So the velocity don't flip weirdly when walking on edges
				const FMovementDelta Velocity = ConstrainedDeltaState.SurfaceProject(GroundedState.ImpactNormal, CurrentWorldUp);
				const FMovementDelta Delta = ConstrainedDeltaState.SurfaceProject(ImpactNormal, CurrentWorldUp);
				return FMovementDelta(Delta.Delta, Velocity.Velocity);
			}
			else
			{
				FMovementDelta ReflectedDeltaState;
				ReflectedDeltaState.Delta = Math::GetReflectionVector(DeltaState.Delta, Impact.Normal);
				ReflectedDeltaState.Velocity = Math::GetReflectionVector(DeltaState.Velocity, Impact.Normal);

				return ReflectedDeltaState;
				// const FVector GroundNormal = GroundedState.Normal;
				// const FVector ImpactNormal = Impact.Normal.GetImpactNormalProjectedAlongSurface(GroundNormal, CurrentWorldUp);

				// // On blocking hits, project the movement on the obstruction while following the grounding plane
				// const FVector Tangent = ImpactNormal.CrossProduct(GroundNormal).GetSafeNormal();
				// const FVector ObstructionUpAlongGround = Tangent.CrossProduct(ImpactNormal).GetSafeNormal(GroundNormal);
				
				// FMovementDelta ConstrainedDeltaState = DeltaState.SurfaceProject(ObstructionUpAlongGround, CurrentWorldUp);
				// FMovementDelta ProjectedDelta = ConstrainedDeltaState.PlaneProject(ImpactNormal);
				// return FMovementDelta(ProjectedDelta.Delta, ConstrainedDeltaState.Velocity.GetSafeNormal() * ProjectedDelta.Velocity.Size());	

			}
		}
		else
		{
			// This is a landing impact
			if(bHitCanBeGround)
			{
				FMovementDelta ConstrainedDeltaState = DeltaState;

				// On grounded impacts, we remove the vertical part
				// unless this is the horizontal movement since the vertical part might be following the ground
				// Its important that the vertical part is removed first, else that part will be redirected
				// to follow the ground on slopes
				if(DeltaStateType != EMovementIterationDeltaStateType::Horizontal)
				{
					ConstrainedDeltaState = ConstrainedDeltaState.GetHorizontalPart(CurrentWorldUp);
				}

				ConstrainedDeltaState = ConstrainedDeltaState.PlaneProject(CurrentWorldUp);
				ConstrainedDeltaState = ConstrainedDeltaState.SurfaceProject(Impact.Normal, CurrentWorldUp);
				return ConstrainedDeltaState;
			}

			// Generic impact
			else
			{
				// REFLECT
				// const FMovementDelta ConstrainedDeltaState = DeltaState.PlaneProject(Impact.Normal);
				FMovementDelta ReflectedDeltaState;
				ReflectedDeltaState.Delta = Math::GetReflectionVector(DeltaState.Delta, Impact.Normal);
				ReflectedDeltaState.Velocity = Math::GetReflectionVector(DeltaState.Velocity, Impact.Normal);

				return ReflectedDeltaState;
				
				// If we used to have velocity going into the wall, but the wall impact kills all velocity
				// we keep a small portion so we will continue going into the wall the next time;
				// FVector ConstrainedVelocity = ConstrainedDeltaState.Velocity;
				// if(!DeltaState.Velocity.IsNearlyZero())
				// 	ConstrainedVelocity = ConstrainedDeltaState.Velocity.GetClampedToSize(1.0, ConstrainedDeltaState.Velocity.Size()); 

				// return FMovementDelta(ConstrainedDeltaState.Delta, ConstrainedVelocity);
			}
		}
	}
}
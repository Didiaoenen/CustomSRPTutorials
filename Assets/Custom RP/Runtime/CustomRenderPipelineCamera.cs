﻿using UnityEngine;

namespace LL
{
	[DisallowMultipleComponent, RequireComponent(typeof(Camera))]
	public class CustomRenderPipelineCamera : MonoBehaviour 
	{

		[SerializeField]
		CameraSettings settings = default;

		public CameraSettings Settings => settings ?? (settings = new CameraSettings());
	}
}
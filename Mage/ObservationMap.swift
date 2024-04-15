//
//  ObservationMap.swift
//  MAGE
//
//  Created by Daniel Barela on 4/5/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

class ObservationMap: DataSourceMap {
    override var REFRESH_KEY: String {
        "ObservationMapDateUpdated"
    }
    let OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID = "OBSERVATION_ICON"

    func addFeatures(features: AnnotationsAndOverlays, mapView: MKMapView) async {
        await super.addFeatures(features: features, mapView: mapView)
        await mapView.showAnnotations(features.annotations, animated: true)
    }

    override func viewForAnnotation(annotation: any MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let annotation = annotation as? ObservationMapItemAnnotation else {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID)

        if let annotationView = annotationView {
            annotationView.annotation = annotation
        } else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID)
            annotationView?.isEnabled = true
        }

        if let iconPath = annotation.mapItem.iconPath, let annotationView = annotationView {
            let image = ObservationImage.imageAtPath(imagePath: iconPath)
            annotationView.image = image
            annotationView.centerOffset = CGPoint(x: 0, y: -(image.size.height/2.0))
            annotationView.accessibilityLabel = "Observation"
            annotationView.accessibilityValue = "Observation"
            annotationView.displayPriority = .required
            annotationView.canShowCallout = true
        }
        return annotationView
    }

    override func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let overlay = overlay as? ObservationAccuracy {
            let renderer = ObservationAccuracyRenderer(overlay: overlay)
            if let scheme = scheme {
                renderer.applyTheme(withContainerScheme: scheme)
            }
            return renderer
        }
        return standardRenderer(overlay: overlay)
    }
}